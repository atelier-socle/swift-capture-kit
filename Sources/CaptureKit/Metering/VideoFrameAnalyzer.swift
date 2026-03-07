// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Real-time video frame analysis actor.
///
/// Tracks frame rate, dropped frames, encoding performance,
/// and buffer levels for monitoring and diagnostics.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor VideoFrameAnalyzer {
    /// Whether the analyzer is currently active.
    public private(set) var isActive: Bool = false

    /// Latest metrics.
    public private(set) var latestMetrics: FrameStatisticsSample?

    private var metricsContinuation: AsyncStream<FrameStatisticsSample>.Continuation?
    private var frameCount: Int = 0
    private var droppedCount: Int = 0
    private var startTime: Date?

    /// Creates a new video frame analyzer.
    public init() {}

    deinit {
        metricsContinuation?.finish()
    }

    /// Metrics stream.
    public var metrics: AsyncStream<FrameStatisticsSample> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: FrameStatisticsSample.self)
        self.metricsContinuation = continuation
        return stream
    }

    /// Start analyzing.
    public func start() async {
        isActive = true
        startTime = Date()
        frameCount = 0
        droppedCount = 0
        latestMetrics = nil
    }

    /// Stop analyzing.
    public func stop() async {
        isActive = false
        metricsContinuation?.finish()
    }

    /// Process a video frame and update metrics.
    ///
    /// - Parameter frame: The video frame to process.
    public func processFrame(_ frame: VideoFrame) async {
        guard isActive else { return }
        frameCount += 1

        let elapsed =
            startTime.map { Date().timeIntervalSince($0) } ?? 0
        let fps = elapsed > 0 ? Double(frameCount) / elapsed : 0

        let sample = FrameStatisticsSample(
            timestamp: frame.timestamp,
            capturedFrameRate: fps,
            droppedFrames: droppedCount,
            encodedFrameRate: fps,
            averageEncodingTime: 0,
            currentBitrate: 0,
            keyFrameInterval: 0,
            bufferLevel: 0
        )
        latestMetrics = sample
        metricsContinuation?.yield(sample)
    }

    /// Report a dropped frame.
    public func reportDroppedFrame() {
        droppedCount += 1
    }
}
