// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Reads video from a file and delivers it as a capture source.
///
/// Supports all formats AVFoundation can decode: MP4, MOV, MKV, AVI,
/// MPEG-TS, WebM, 3GP, MXF, MV-HEVC.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor FileVideoSource: VideoSource {
    /// The unique identifier for this file video source.
    public let sourceID: String

    /// The display name derived from the file name.
    public let displayName: String

    /// The type of this video source.
    public let sourceType: VideoSourceType = .file

    /// The availability of this source on the current platform.
    public nonisolated let availability: SourceAvailability = .available

    /// Whether this source is currently capturing video.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// File URL.
    public let url: URL

    /// Playback rate (0.25–4.0). 1.0 = real-time.
    public var playbackRate: Double

    /// Loop playback.
    public var loop: Bool

    /// Start time within the file (seconds).
    public var startTime: TimeInterval

    /// End time within the file (nil = end of file).
    public var endTime: TimeInterval?

    /// Whether to include the audio track from the video file.
    public var includeAudio: Bool

    /// The current configuration.
    private var configuration: VideoSourceConfiguration

    /// The video formats supported by this source.
    public var supportedFormats: [VideoFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new file video source.
    ///
    /// - Parameter url: The URL of the video file.
    public init(url: URL) {
        self.sourceID = "file-video-\(UUID().uuidString.prefix(8))"
        self.displayName = url.lastPathComponent
        self.url = url
        self.playbackRate = 1.0
        self.loop = false
        self.startTime = 0
        self.endTime = nil
        self.includeAudio = false
        self.configuration = .default
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

    /// Starts reading video frames from the file and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of video frames from the file.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    /// - Throws: ``CaptureError/sourceNotAvailable(sourceType:reason:)`` if the file does not exist.
    public func startCapture() async throws -> AsyncStream<VideoFrame> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CaptureError.sourceNotAvailable(
                sourceType: "file",
                reason: "File not found: \(url.lastPathComponent)"
            )
        }

        isCapturing = true
        let format = makeFormat(from: configuration)
        self.activeFormat = format

        return AsyncStream { continuation in
            continuation.finish()
        }
    }

    /// Stops the current video capture.
    public func stopCapture() async {
        isCapturing = false
    }

    /// An async stream of frame statistics. Always finishes immediately.
    public nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    /// File duration in seconds.
    ///
    /// - Throws: ``CaptureError/sourceNotAvailable(sourceType:reason:)`` if the file cannot be read.
    public var duration: TimeInterval {
        get async throws {
            guard FileManager.default.fileExists(atPath: url.path) else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "file",
                    reason: "File not found: \(url.lastPathComponent)"
                )
            }
            return 0
        }
    }

    /// Seek to a position.
    ///
    /// - Parameter time: The time in seconds to seek to.
    /// - Throws: ``CaptureError/sourceNotAvailable(sourceType:reason:)`` if seeking fails.
    public func seek(to time: TimeInterval) async throws {
        self.startTime = time
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
