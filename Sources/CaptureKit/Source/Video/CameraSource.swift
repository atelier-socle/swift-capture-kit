// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Captures video from built-in cameras (front, back, ultra-wide, telephoto).
///
/// Uses AVCaptureSession + AVCaptureDevice for capture.
/// Supports camera switching, zoom, torch, depth data, and simultaneous photo capture.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor CameraSource: VideoSource {
    /// The unique identifier for this camera source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Camera"

    /// The type of this video source.
    public let sourceType: VideoSourceType = .builtInCamera

    /// The availability of this source, requiring camera permission.
    public nonisolated var availability: SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: true,
            requiredPermissions: [.camera],
            minimumOSVersion: nil,
            notes: nil
        )
    }

    /// Whether this source is currently capturing video.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// Camera position.
    public var position: CameraPosition

    /// Camera device type preference.
    public var deviceType: CameraDeviceType

    /// Torch mode.
    public var torchMode: TorchMode

    /// Zoom factor (1.0 = no zoom).
    public var zoomFactor: Double

    /// Minimum zoom factor.
    public var minZoomFactor: Double { 1.0 }

    /// Maximum zoom factor (device-dependent, default conservative).
    public var maxZoomFactor: Double { 10.0 }

    /// Whether to deliver depth data alongside video.
    public var depthDataDelivery: Bool

    /// Camera Control support (iPhone 16+, iOS 26).
    public var captureControlEnabled: Bool

    /// The current configuration.
    private var configuration: VideoSourceConfiguration

    /// The capture engine used for video capture.
    private let captureEngine: any VideoCaptureProviding

    /// The video formats supported by this source.
    public var supportedFormats: [VideoFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new camera source.
    ///
    /// - Parameter position: The camera position. Defaults to `.back`.
    public init(position: CameraPosition = .back) {
        self.sourceID = "camera-\(UUID().uuidString.prefix(8))"
        self.position = position
        self.deviceType = .wideAngle
        self.torchMode = .off
        self.zoomFactor = 1.0
        self.depthDataDelivery = false
        self.captureControlEnabled = false
        self.configuration = .default
        #if os(visionOS)
            self.captureEngine = VisionOSVideoCaptureEngine()
        #else
            self.captureEngine = SystemVideoCaptureEngine()
        #endif
    }

    /// Creates a new camera source with an injected capture engine (for testing).
    ///
    /// - Parameters:
    ///   - position: The camera position. Defaults to `.back`.
    ///   - captureEngine: The capture engine to use.
    init(position: CameraPosition = .back, captureEngine: any VideoCaptureProviding) {
        self.sourceID = "camera-\(UUID().uuidString.prefix(8))"
        self.position = position
        self.deviceType = .wideAngle
        self.torchMode = .off
        self.zoomFactor = 1.0
        self.depthDataDelivery = false
        self.captureControlEnabled = false
        self.configuration = .default
        self.captureEngine = captureEngine
    }

    /// Configures this source with the given video source configuration.
    ///
    /// - Parameter configuration: The desired video source configuration.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if currently capturing.
    public func configure(_ configuration: VideoSourceConfiguration) async throws {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        self.configuration = configuration
        self.activeFormat = makeFormat(from: configuration)
    }

    /// Starts capturing video and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of captured video frames.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    public func startCapture() async throws -> AsyncStream<VideoFrame> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        isCapturing = true
        let config = self.configuration
        self.activeFormat = makeFormat(from: config)

        let stream = try await captureEngine.startCapture(
            configuration: config,
            position: position,
            deviceType: deviceType
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

    /// Switch camera position without stopping capture.
    ///
    /// - Parameter position: The new camera position.
    public func switchCamera(to position: CameraPosition) async throws {
        try await captureEngine.switchCamera(to: position)
        self.position = position
    }

    /// Capture a still photo while recording video.
    ///
    /// - Parameter settings: The photo capture settings. Defaults to `nil`.
    /// - Returns: The captured photo.
    /// - Throws: ``CaptureError/sourceNotAvailable(sourceType:reason:)`` as hardware is required.
    public func capturePhoto(settings: PhotoCaptureSettings? = nil) async throws -> CapturedPhoto {
        try await captureEngine.capturePhoto(settings: settings)
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
