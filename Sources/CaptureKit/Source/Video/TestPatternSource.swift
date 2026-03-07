// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Generates standard broadcast test patterns.
///
/// Supports SMPTE bars, EBU bars, grid, checkerboard, gray ramp,
/// and other calibration patterns.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor TestPatternSource: VideoSource {
    /// The unique identifier for this test pattern source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Test Pattern Generator"

    /// The type of this video source.
    public let sourceType: VideoSourceType = .generator

    /// The availability of this source on the current platform.
    public nonisolated let availability: SourceAvailability = .available

    /// Whether this source is currently generating video.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// The test pattern to generate.
    public var pattern: TestPattern

    /// The resolution for generated frames.
    private var resolution: VideoResolution

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

    /// Creates a new test pattern source.
    ///
    /// - Parameters:
    ///   - pattern: The test pattern to generate. Defaults to `.smpteBars`.
    ///   - resolution: The video resolution. Defaults to `.p1080`.
    ///   - frameRate: The frame rate. Defaults to `.fps30`.
    public init(
        pattern: TestPattern = .smpteBars,
        resolution: VideoResolution = .p1080,
        frameRate: FrameRate = .fps30
    ) {
        self.sourceID = "pattern-\(UUID().uuidString.prefix(8))"
        self.pattern = pattern
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

    /// Starts generating test pattern video frames and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of test pattern video frames.
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
        let frameDuration = 1.0 / configuration.frameRate.value
        let pattern = self.pattern
        let analyzer = statsAnalyzer
        let statsContinuation = _frameStatisticsContinuation

        return AsyncStream { continuation in
            let task = Task { @concurrent in
                var sequenceNumber: Int64 = 0
                let frameData = TestPatternSource.generatePattern(
                    pattern, width: width, height: height
                )

                while !Task.isCancelled {
                    let frame = VideoFrame(
                        data: frameData,
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

    /// Stops generating test pattern video frames.
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

    // MARK: - Pattern Generation

    /// Generates frame data for the specified test pattern.
    static func generatePattern(_ pattern: TestPattern, width: Int, height: Int) -> Data {
        switch pattern {
        case .smpteBars, .smpteHD:
            return generateSMPTEBars(width: width, height: height)
        case .ebu100:
            return generateEBUBars(width: width, height: height, amplitude: 1.0)
        case .ebu75:
            return generateEBUBars(width: width, height: height, amplitude: 0.75)
        case .grid:
            return generateGrid(width: width, height: height)
        case .checkerboard:
            return generateCheckerboard(width: width, height: height)
        case .grayRamp:
            return generateGrayRamp(width: width, height: height)
        case .colorChecker, .zoneplate, .countdown:
            return generateSMPTEBars(width: width, height: height)
        }
    }

    /// Generates 75% SMPTE color bars.
    private static func generateSMPTEBars(width: Int, height: Int) -> Data {
        // 7 bars: White, Yellow, Cyan, Green, Magenta, Red, Blue (BGRA at 75%)
        let bars: [BGRAPixel] = [
            BGRAPixel(b: 191, g: 191, r: 191, a: 255),
            BGRAPixel(b: 0, g: 191, r: 191, a: 255),
            BGRAPixel(b: 191, g: 191, r: 0, a: 255),
            BGRAPixel(b: 0, g: 191, r: 0, a: 255),
            BGRAPixel(b: 191, g: 0, r: 191, a: 255),
            BGRAPixel(b: 0, g: 0, r: 191, a: 255),
            BGRAPixel(b: 191, g: 0, r: 0, a: 255)
        ]
        return generateVerticalBars(bars, width: width, height: height)
    }

    /// Generates EBU color bars at the given amplitude.
    private static func generateEBUBars(
        width: Int, height: Int, amplitude: Float
    ) -> Data {
        let v = UInt8(clamping: Int(255.0 * amplitude))
        let bars: [BGRAPixel] = [
            BGRAPixel(b: v, g: v, r: v, a: 255),
            BGRAPixel(b: 0, g: v, r: v, a: 255),
            BGRAPixel(b: v, g: v, r: 0, a: 255),
            BGRAPixel(b: 0, g: v, r: 0, a: 255),
            BGRAPixel(b: v, g: 0, r: v, a: 255),
            BGRAPixel(b: 0, g: 0, r: v, a: 255),
            BGRAPixel(b: v, g: 0, r: 0, a: 255)
        ]
        return generateVerticalBars(bars, width: width, height: height)
    }

    /// Generates vertical color bars.
    private static func generateVerticalBars(
        _ bars: [BGRAPixel], width: Int, height: Int
    ) -> Data {
        let barCount = bars.count
        var data = Data(count: width * height * 4)
        data.withUnsafeMutableBytes { rawBuffer in
            let buffer = rawBuffer.bindMemory(to: UInt8.self)
            for y in 0..<height {
                for x in 0..<width {
                    let barIndex = min(x * barCount / width, barCount - 1)
                    let pixel = bars[barIndex]
                    let offset = (y * width + x) * 4
                    buffer[offset] = pixel.b
                    buffer[offset + 1] = pixel.g
                    buffer[offset + 2] = pixel.r
                    buffer[offset + 3] = pixel.a
                }
            }
        }
        return data
    }

    /// Generates a grid pattern (white lines on black).
    private static func generateGrid(width: Int, height: Int) -> Data {
        let gridSpacing = 64
        var data = Data(count: width * height * 4)
        data.withUnsafeMutableBytes { rawBuffer in
            let buffer = rawBuffer.bindMemory(to: UInt8.self)
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * 4
                    let isLine = x % gridSpacing == 0 || y % gridSpacing == 0
                    let value: UInt8 = isLine ? 255 : 0
                    buffer[offset] = value
                    buffer[offset + 1] = value
                    buffer[offset + 2] = value
                    buffer[offset + 3] = 255
                }
            }
        }
        return data
    }

    /// Generates a checkerboard pattern.
    private static func generateCheckerboard(width: Int, height: Int) -> Data {
        let squareSize = 32
        var data = Data(count: width * height * 4)
        data.withUnsafeMutableBytes { rawBuffer in
            let buffer = rawBuffer.bindMemory(to: UInt8.self)
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * 4
                    let isWhite = ((x / squareSize) + (y / squareSize)) % 2 == 0
                    let value: UInt8 = isWhite ? 255 : 0
                    buffer[offset] = value
                    buffer[offset + 1] = value
                    buffer[offset + 2] = value
                    buffer[offset + 3] = 255
                }
            }
        }
        return data
    }

    /// Generates a horizontal gray ramp from black (left) to white (right).
    private static func generateGrayRamp(width: Int, height: Int) -> Data {
        var data = Data(count: width * height * 4)
        data.withUnsafeMutableBytes { rawBuffer in
            let buffer = rawBuffer.bindMemory(to: UInt8.self)
            for y in 0..<height {
                for x in 0..<width {
                    let offset = (y * width + x) * 4
                    let value = UInt8(clamping: x * 255 / max(width - 1, 1))
                    buffer[offset] = value
                    buffer[offset + 1] = value
                    buffer[offset + 2] = value
                    buffer[offset + 3] = 255
                }
            }
        }
        return data
    }
}
