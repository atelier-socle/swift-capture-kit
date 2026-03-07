// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Orchestrates simultaneous capture from multiple cameras.
///
/// Uses AVCaptureMultiCamSession on iOS (iPhone 11+) for front+back,
/// and manages multiple AVCaptureDevice instances on macOS for external cameras.
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

    /// The capture engine used for video capture.
    private let captureEngine: any VideoCaptureProviding

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
        #if os(visionOS)
            self.captureEngine = VisionOSVideoCaptureEngine()
        #else
            self.captureEngine = SystemVideoCaptureEngine()
        #endif
    }

    /// Creates a new multi-camera source with an injected capture engine (for testing).
    ///
    /// - Parameters:
    ///   - configuration: The multi-camera configuration.
    ///   - captureEngine: The capture engine to use.
    init(configuration: MultiCameraConfiguration, captureEngine: any VideoCaptureProviding) {
        self.sourceID = "multicam-\(UUID().uuidString.prefix(8))"
        self.multiCameraConfiguration = configuration
        self.configuration = .default
        self.captureEngine = captureEngine
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
        let config = self.configuration
        self.activeFormat = makeFormat(from: config)

        let stream = try await captureEngine.startCapture(
            configuration: config,
            position: .back,
            deviceType: .wideAngle
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

    /// Stops the current video capture.
    public func stopCapture() async {
        await captureEngine.stopCapture()
        isCapturing = false
    }

    /// An async stream of frame statistics. Always finishes immediately.
    public nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        AsyncStream { continuation in
            continuation.finish()
        }
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
        let stream = try await captureEngine.startCapture(
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
