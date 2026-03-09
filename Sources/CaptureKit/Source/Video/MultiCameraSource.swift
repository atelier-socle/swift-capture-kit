// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Orchestrates simultaneous capture from multiple cameras.
///
/// Each camera gets its own capture engine (AVCaptureSession) so sessions
/// don't interfere. On macOS this uses separate AVCaptureSessions per camera;
/// on iOS with multi-cam hardware it uses AVCaptureMultiCamSession.
@available(macOS 14.0, iOS 17.0, *)
public actor MultiCameraSource: VideoSource {
    /// The unique identifier for this multi-camera source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Multi-Camera"

    /// The type of this video source.
    public let sourceType: VideoSourceType = .multiCamera

    /// The availability of this source, requiring camera permission.
    public nonisolated var availability: SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: true,
            requiredPermissions: [.camera],
            minimumOSVersion: nil,
            notes: "iOS requires iPhone 11+ with AVCaptureMultiCamSession support"
        )
    }

    /// Whether this source is currently capturing video.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// Multi-camera configuration.
    public var multiCameraConfiguration: MultiCameraConfiguration

    /// Labels for all configured cameras.
    public var cameraLabels: [String] {
        multiCameraConfiguration.cameras.map(\.label)
    }

    /// Number of active camera streams.
    public var activeCameraCount: Int {
        multiCameraConfiguration.cameras.count
    }

    /// The current configuration.
    private var configuration: VideoSourceConfiguration

    /// Factory that creates a new capture engine per camera.
    private let engineFactory: @Sendable () -> any VideoCaptureProviding

    /// One capture engine per camera label — each owns its own AVCaptureSession.
    private var captureEngines: [String: any VideoCaptureProviding] = [:]

    /// Frame statistics tracking.
    private let statsAnalyzer = VideoFrameAnalyzer()
    private let _frameStatisticsStream: AsyncStream<FrameStatisticsSample>
    private let _frameStatisticsContinuation: AsyncStream<FrameStatisticsSample>.Continuation

    /// The video formats supported by this source.
    public var supportedFormats: [VideoFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new multi-camera source.
    ///
    /// - Parameter configuration: The multi-camera configuration.
    public init(configuration: MultiCameraConfiguration) {
        self.sourceID = "multicam-\(UUID().uuidString.prefix(8))"
        self.multiCameraConfiguration = configuration
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: FrameStatisticsSample.self)
        self._frameStatisticsStream = stream
        self._frameStatisticsContinuation = continuation
        #if os(visionOS)
            self.engineFactory = { VisionOSVideoCaptureEngine() }
        #else
            self.engineFactory = { SystemVideoCaptureEngine() }
        #endif
    }

    /// Creates a new multi-camera source with an injected capture engine factory (for testing).
    ///
    /// - Parameters:
    ///   - configuration: The multi-camera configuration.
    ///   - captureEngine: A capture engine instance used as the factory template.
    ///     Each camera stream will reuse this same instance in tests (mock supports it).
    init(configuration: MultiCameraConfiguration, captureEngine: any VideoCaptureProviding) {
        self.sourceID = "multicam-\(UUID().uuidString.prefix(8))"
        self.multiCameraConfiguration = configuration
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: FrameStatisticsSample.self)
        self._frameStatisticsStream = stream
        self._frameStatisticsContinuation = continuation
        let sharedEngine = captureEngine
        self.engineFactory = { sharedEngine }
    }

    /// Configures this source with the given video source configuration.
    ///
    /// - Parameter configuration: The desired video source configuration.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if currently capturing.
    /// - Throws: ``CaptureError/invalidConfiguration(_:)`` if fewer than 2 cameras.
    public func configure(_ configuration: VideoSourceConfiguration) async throws {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        try multiCameraConfiguration.validate()
        self.configuration = configuration
        self.activeFormat = makeFormat(from: configuration)
    }

    /// Starts capturing from all cameras and returns a stream from the first camera.
    ///
    /// - Returns: An asynchronous stream of video frames from the first camera.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    /// - Throws: ``CaptureError/invalidConfiguration(_:)`` if fewer than 2 cameras.
    public func startCapture() async throws -> AsyncStream<VideoFrame> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        try multiCameraConfiguration.validate()
        isCapturing = true
        await statsAnalyzer.start()
        let config = self.configuration
        self.activeFormat = makeFormat(from: config)

        let primaryCamera = multiCameraConfiguration.cameras[0]
        let engine = engineFactory()
        captureEngines[primaryCamera.label] = engine

        let stream = try await engine.startCapture(
            configuration: config,
            position: primaryCamera.device.position,
            deviceType: primaryCamera.device.deviceType
        )

        let analyzer = statsAnalyzer
        let statsContinuation = _frameStatisticsContinuation

        return AsyncStream { continuation in
            let task = Task {
                var seq: Int64 = 0
                for await sample in stream {
                    let frame = VideoFrame(
                        data: sample.data,
                        format: sample.format,
                        timestamp: sample.timestamp,
                        isKeyFrame: sample.isKeyFrame,
                        sequenceNumber: seq
                    )
                    continuation.yield(frame)
                    await analyzer.processFrame(frame)
                    if let latest = await analyzer.latestMetrics {
                        statsContinuation.yield(latest)
                    }
                    seq += 1
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Stops the current video capture for all cameras.
    public func stopCapture() async {
        for engine in captureEngines.values {
            await engine.stopCapture()
        }
        captureEngines.removeAll()
        isCapturing = false
        await statsAnalyzer.stop()
    }

    /// An async stream of real-time frame statistics.
    public nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        _frameStatisticsStream
    }

    /// Get the video stream for a specific camera by label.
    ///
    /// - Parameter label: The camera label to get the stream for.
    /// - Returns: An asynchronous stream of video frames from the specified camera.
    /// - Throws: ``CaptureError/deviceNotFound(deviceID:)`` if the label is not found.
    public func stream(for label: String) async throws -> AsyncStream<VideoFrame> {
        guard let camera = multiCameraConfiguration.cameras.first(where: { $0.label == label }) else {
            throw CaptureError.deviceNotFound(deviceID: label)
        }

        let config = self.configuration

        // Reuse existing engine for this camera, or create a new one
        let engine: any VideoCaptureProviding
        if let existing = captureEngines[label] {
            engine = existing
        } else {
            let newEngine = engineFactory()
            captureEngines[label] = newEngine
            engine = newEngine
        }

        let stream = try await engine.startCapture(
            configuration: config,
            position: camera.device.position,
            deviceType: camera.device.deviceType
        )

        return AsyncStream { continuation in
            let task = Task {
                var seq: Int64 = 0
                for await sample in stream {
                    let frame = VideoFrame(
                        data: sample.data,
                        format: sample.format,
                        timestamp: sample.timestamp,
                        isKeyFrame: sample.isKeyFrame,
                        sequenceNumber: seq
                    )
                    continuation.yield(frame)
                    seq += 1
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func makeFormat(from config: VideoSourceConfiguration) -> VideoFormat {
        VideoFormat(
            resolution: config.resolution,
            frameRate: config.frameRate,
            pixelFormat: config.pixelFormat,
            colorSpace: config.colorSpace,
            dynamicRange: config.dynamicRange
        )
    }
}
