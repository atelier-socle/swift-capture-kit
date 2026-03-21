// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("VideoFrameAnalyzer", .timeLimit(.minutes(1)))
struct VideoFrameAnalyzerTests {

    private func makeFrame(
        timestamp: TimeInterval = 0
    ) -> VideoFrame {
        VideoFrame(
            data: Data([0, 1, 2, 3]),
            format: VideoFormat(
                resolution: .p1080,
                frameRate: .fps30,
                pixelFormat: .bgra),
            timestamp: timestamp,
            isKeyFrame: true,
            sequenceNumber: 0
        )
    }

    @Test("not active initially")
    func notActiveInitially() async {
        let analyzer = VideoFrameAnalyzer()
        #expect(await analyzer.isActive == false)
    }

    @Test("start sets isActive")
    func startSetsActive() async {
        let analyzer = VideoFrameAnalyzer()
        await analyzer.start()
        #expect(await analyzer.isActive == true)
        await analyzer.stop()
    }

    @Test("stop sets isActive false")
    func stopSetsInactive() async {
        let analyzer = VideoFrameAnalyzer()
        await analyzer.start()
        await analyzer.stop()
        #expect(await analyzer.isActive == false)
    }

    @Test("metrics stream exists")
    func metricsStreamExists() async {
        let analyzer = VideoFrameAnalyzer()
        _ = await analyzer.metrics
    }

    @Test("processFrame when not active is no-op")
    func processWhenNotActive() async {
        let analyzer = VideoFrameAnalyzer()
        await analyzer.processFrame(makeFrame())
        #expect(await analyzer.latestMetrics == nil)
    }

    @Test("processFrame updates latestMetrics")
    func processUpdatesMetrics() async {
        let analyzer = VideoFrameAnalyzer()
        await analyzer.start()
        await analyzer.processFrame(makeFrame(timestamp: 0.5))
        let metrics = await analyzer.latestMetrics
        #expect(metrics != nil)
        #expect(metrics?.timestamp == 0.5)
        await analyzer.stop()
    }

    @Test("frame count increments")
    func frameCountIncrements() async {
        let analyzer = VideoFrameAnalyzer()
        await analyzer.start()
        await analyzer.processFrame(makeFrame())
        await analyzer.processFrame(makeFrame())
        await analyzer.processFrame(makeFrame())
        let metrics = await analyzer.latestMetrics
        #expect(metrics?.capturedFrameRate ?? 0 > 0)
        await analyzer.stop()
    }

    @Test("reportDroppedFrame increments count")
    func reportDroppedFrame() async {
        let analyzer = VideoFrameAnalyzer()
        await analyzer.start()
        await analyzer.reportDroppedFrame()
        await analyzer.processFrame(makeFrame())
        let metrics = await analyzer.latestMetrics
        #expect(metrics?.droppedFrames == 1)
        await analyzer.stop()
    }

    @Test("latestMetrics is nil initially")
    func latestMetricsNilInitially() async {
        let analyzer = VideoFrameAnalyzer()
        #expect(await analyzer.latestMetrics == nil)
    }

    @Test("start resets counters")
    func startResetsCounters() async {
        let analyzer = VideoFrameAnalyzer()
        await analyzer.start()
        await analyzer.processFrame(makeFrame())
        await analyzer.stop()
        await analyzer.start()
        #expect(await analyzer.latestMetrics == nil)
    }
}
