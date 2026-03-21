// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Generates solid color video frames for testing.
///
/// Each pixel is filled with the specified BGRA color values.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor ColorSource: VideoSource {
    /// The unique identifier for this color source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Color Generator"

    /// The type of this video source.
    public let sourceType: VideoSourceType = .generator

    /// The availability of this source on the current platform.
    public nonisolated let availability: SourceAvailability = .available

    /// Whether this source is currently generating video.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// The solid color to generate.
    public var color: CaptureColor

    /// The resolution for generated frames.
    private var resolution: VideoResolution

    /// The current configuration.
    private var configuration: VideoSourceConfiguration

    /// Frame statistics tracking.
    private let statsAnalyzer = VideoFrameAnalyzer()
    private let _frameStatisticsStream: AsyncStream<FrameStatisticsSample>
    private let _frameStatisticsContinuation: AsyncStream<FrameStatisticsSample>.Continuation

    /// The active stream continuation, stored so stopCapture() can finish it.
    private var _streamContinuation: AsyncStream<VideoFrame>.Continuation?

    /// The video formats supported by this source.
    public var supportedFormats: [VideoFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new color source with the specified color, resolution, and frame rate.
    ///
    /// - Parameters:
    ///   - color: The solid color to generate.
    ///   - resolution: The video resolution. Defaults to `.p1080`.
    ///   - frameRate: The frame rate. Defaults to `.fps30`.
    public init(
        color: CaptureColor,
        resolution: VideoResolution = .p1080,
        frameRate: FrameRate = .fps30
    ) {
        self.sourceID = "color-\(UUID().uuidString.prefix(8))"
        self.color = color
        self.resolution = resolution
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

    deinit {
        _streamContinuation?.finish()
        _frameStatisticsContinuation.finish()
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
        self.activeFormat = makeFormat(from: configuration)
    }

    /// Starts generating colored video frames and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of color-filled video frames.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    public func startCapture() async throws -> AsyncStream<VideoFrame> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        isCapturing = true
        await statsAnalyzer.start()

        let format = makeFormat(from: configuration)
        self.activeFormat = format
        let width = resolution.width
        let height = resolution.height
        let pixelCount = width * height
        let frameSize = pixelCount * 4
        let frameDuration = 1.0 / configuration.frameRate.value
        let color = self.color
        let analyzer = statsAnalyzer
        let statsContinuation = _frameStatisticsContinuation

        let (stream, continuation) = AsyncStream.makeStream(of: VideoFrame.self)
        _streamContinuation = continuation

        let task = Task { @concurrent in
            var sequenceNumber: Int64 = 0
            let pixel = ColorSource.makePixel(from: color)

            while !Task.isCancelled {
                var data = Data(count: frameSize)
                data.withUnsafeMutableBytes { rawBuffer in
                    let buffer = rawBuffer.bindMemory(to: UInt8.self)
                    for i in 0..<pixelCount {
                        let offset = i * 4
                        buffer[offset] = pixel.b
                        buffer[offset + 1] = pixel.g
                        buffer[offset + 2] = pixel.r
                        buffer[offset + 3] = pixel.a
                    }
                }

                let frame = VideoFrame(
                    data: data,
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

        return stream
    }

    /// Stops generating colored video frames.
    public func stopCapture() async {
        isCapturing = false
        _streamContinuation?.finish()
        _streamContinuation = nil
        _frameStatisticsContinuation.finish()
        await statsAnalyzer.stop()
    }

    /// An async stream of real-time frame statistics.
    public nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        _frameStatisticsStream
    }

    /// Converts a CaptureColor to BGRA byte values.
    static func makePixel(from color: CaptureColor) -> BGRAPixel {
        BGRAPixel(
            b: UInt8(clamping: Int(color.blue * 255)),
            g: UInt8(clamping: Int(color.green * 255)),
            r: UInt8(clamping: Int(color.red * 255)),
            a: UInt8(clamping: Int(color.alpha * 255))
        )
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
