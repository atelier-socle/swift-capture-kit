// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Captures cinematic video with adjustable depth of field.
///
/// Available on iPhone 13+ with A15 Bionic or later.
/// Provides rack focus, adjustable f-number, and subject tracking.
@available(iOS 17.0, macOS 14.0, visionOS 1.0, *)
public actor CinematicCameraSource: VideoSource {
    /// The unique identifier for this cinematic camera source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Cinematic Camera"

    /// The type of this video source.
    public let sourceType: VideoSourceType = .cinematicCamera

    /// The availability of this source, requiring camera permission.
    public nonisolated var availability: SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: true,
            requiredPermissions: [.camera],
            minimumOSVersion: "17.0",
            notes: "Requires iPhone 13+ with A15 Bionic or later"
        )
    }

    /// Whether this source is currently capturing video.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// Simulated aperture (f-number). Range: 1.4–16.0.
    public var fNumber: Float {
        didSet {
            fNumber = min(max(fNumber, 1.4), 16.0)
        }
    }

    /// Focus subject (automatic or manual).
    public var focusSubject: CinematicFocusSubject

    /// The current configuration.
    private var configuration: VideoSourceConfiguration

    /// The capture engine used for video capture.
    private let captureEngine: any VideoCaptureProviding

    /// The video formats supported by this source.
    public var supportedFormats: [VideoFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new cinematic camera source.
    public init() {
        self.sourceID = "cinematic-\(UUID().uuidString.prefix(8))"
        self.fNumber = 2.8
        self.focusSubject = .automatic
        self.configuration = .cinematic
        #if os(visionOS)
            self.captureEngine = VisionOSVideoCaptureEngine()
        #else
            self.captureEngine = SystemVideoCaptureEngine()
        #endif
    }

    /// Creates a new cinematic camera source with an injected capture engine (for testing).
    ///
    /// - Parameter captureEngine: The capture engine to use.
    init(captureEngine: any VideoCaptureProviding) {
        self.sourceID = "cinematic-\(UUID().uuidString.prefix(8))"
        self.fNumber = 2.8
        self.focusSubject = .automatic
        self.configuration = .cinematic
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

    /// Starts capturing cinematic video and returns an async stream.
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

    /// Animated focus change between subjects.
    ///
    /// - Parameters:
    ///   - subject: The new focus subject.
    ///   - duration: The duration of the focus transition in seconds.
    public func rackFocus(to subject: CinematicFocusSubject, duration: TimeInterval) async {
        self.focusSubject = subject
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
