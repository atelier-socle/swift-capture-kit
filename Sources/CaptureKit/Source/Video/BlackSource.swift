// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Generates solid black video frames.
///
/// Useful for audio-only capture sessions that require a video track,
/// or as a placeholder in multi-output pipelines.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor BlackSource: VideoSource {
    /// The unique identifier for this black source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Black Generator"

    /// The type of this video source.
    public let sourceType: VideoSourceType = .generator

    /// The availability of this source on the current platform.
    public nonisolated let availability: SourceAvailability = .available

    /// Whether this source is currently generating video.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// The resolution for generated frames.
    private var resolution: VideoResolution

    /// The frame rate for generated frames.
    private var frameRate: FrameRate

    /// The current configuration.
    private var configuration: VideoSourceConfiguration

    /// Frame statistics tracking.
    private let statsAnalyzer = VideoFrameAnalyzer()
    private let _frameStatisticsStream: AsyncStream<FrameStatisticsSample>
    private let _frameStatisticsContinuation: AsyncStream<FrameStatisticsSample>.Continuation

    /// The video formats supported by this source.
    public var supportedFormats: [VideoFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new black source with the specified resolution and frame rate.
    ///
    /// - Parameters:
    ///   - resolution: The video resolution. Defaults to `.p1080`.
    ///   - frameRate: The frame rate. Defaults to `.fps30`.
    public init(resolution: VideoResolution = .p1080, frameRate: FrameRate = .fps30) {
        self.sourceID = "black-\(UUID().uuidString.prefix(8))"
        self.resolution = resolution
        self.frameRate = frameRate
        let (stream, continuation) = AsyncStream.makeStream(of: FrameStatisticsSample.self)
        self._frameStatisticsStream = stream
        self._frameStatisticsContinuation = continuation
        self.configuration = VideoSourceConfiguration(
            resolution: resolution,
            frameRate: frameRate,
            pixelFormat: .bgra,
            colorSpace: .bt709,
            dynamicRange: .sdr,
            stabilization: .off,
            focusMode: .locked,
            exposureMode: .locked,
            whiteBalanceMode: .locked
        )
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
        self.resolution = configuration.resolution
        self.frameRate = configuration.frameRate
        self.activeFormat = makeFormat(from: configuration)
    }

    /// Starts generating black video frames and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of zero-filled video frames.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    public func startCapture() async throws -> AsyncStream<VideoFrame> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        isCapturing = true
        await statsAnalyzer.start()

        let format = makeFormat(from: configuration)
        self.activeFormat = format
        let frameSize = resolution.width * resolution.height * 4
        let frameDuration = 1.0 / frameRate.value
        let analyzer = statsAnalyzer
        let statsContinuation = _frameStatisticsContinuation

        return AsyncStream { continuation in
            let task = Task { @concurrent in
                var sequenceNumber: Int64 = 0

                while !Task.isCancelled {
                    let frame = VideoFrame(
                        data: Data(count: frameSize),
                        format: format,
                        timestamp: TimeInterval(sequenceNumber) * frameDuration,
                        isKeyFrame: sequenceNumber % 30 == 0,
                        sequenceNumber: sequenceNumber
                    )
                    continuation.yield(frame)
                    await analyzer.processFrame(frame)
                    if let latest = await analyzer.latestMetrics {
                        statsContinuation.yield(latest)
                    }
                    sequenceNumber += 1
                    try? await Task.sleep(for: .seconds(frameDuration))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Stops generating black video frames.
    public func stopCapture() async {
        isCapturing = false
        await statsAnalyzer.stop()
    }

    /// An async stream of real-time frame statistics.
    public nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        _frameStatisticsStream
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
