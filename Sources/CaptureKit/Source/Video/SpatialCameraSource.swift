// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if os(visionOS)
    import Foundation

    /// Captures spatial video (MV-HEVC stereoscopic) on visionOS.
    ///
    /// Delivers stereoscopic left/right eye pairs for Apple Vision Pro content.
    @available(visionOS 1.0, *)
    public actor SpatialCameraSource: VideoSource {
        /// The unique identifier for this spatial camera source.
        public let sourceID: String

        /// The display name shown in UI or logs.
        public let displayName: String = "Spatial Camera"

        /// The type of this video source.
        public let sourceType: VideoSourceType = .spatialCamera

        /// The availability of this source, requiring camera permission.
        public nonisolated var availability: SourceAvailability {
            SourceAvailability(
                isAvailableOnCurrentPlatform: true,
                isAvailableOnCurrentDevice: true,
                requiredPermissions: [.camera],
                minimumOSVersion: "1.0",
                notes: "visionOS only — requires Apple Vision Pro"
            )
        }

        /// Whether this source is currently capturing video.
        public private(set) var isCapturing: Bool = false

        /// The currently active video format, if configured or capturing.
        public private(set) var activeFormat: VideoFormat?

        /// Spatial capture mode.
        public var spatialMode: SpatialCaptureMode

        /// The current configuration.
        private var configuration: VideoSourceConfiguration

        /// The capture engine used for video capture.
        private let captureEngine: any VideoCaptureProviding

        /// The video formats supported by this source.
        public var supportedFormats: [VideoFormat] {
            [makeFormat(from: configuration)]
        }

        /// Creates a new spatial camera source.
        ///
        /// - Parameter mode: The spatial capture mode. Defaults to `.stereoscopic`.
        public init(mode: SpatialCaptureMode = .stereoscopic) {
            self.sourceID = "spatial-\(UUID().uuidString.prefix(8))"
            self.spatialMode = mode
            self.configuration = .spatialVideo
            self.captureEngine = VisionOSVideoCaptureEngine()
        }

        /// Creates a new spatial camera source with an injected capture engine (for testing).
        ///
        /// - Parameters:
        ///   - mode: The spatial capture mode. Defaults to `.stereoscopic`.
        ///   - captureEngine: The capture engine to use.
        init(mode: SpatialCaptureMode = .stereoscopic, captureEngine: any VideoCaptureProviding) {
            self.sourceID = "spatial-\(UUID().uuidString.prefix(8))"
            self.spatialMode = mode
            self.configuration = .spatialVideo
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

        /// Starts capturing spatial video and returns an async stream.
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
#endif
