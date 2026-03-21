// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("MeteringEvent", .timeLimit(.minutes(1)))
struct MeteringEventTests {

    @Test("audioLevel case carries sample")
    func audioLevelCase() {
        let sample = AudioLevelSample(
            timestamp: 1.0, peakLevel: -3.0,
            rmsLevel: -12.0, channels: [])
        let event = MeteringEvent.audioLevel(sample)
        if case .audioLevel(let s) = event {
            #expect(s.timestamp == 1.0)
        } else {
            Issue.record("Expected audioLevel")
        }
    }

    @Test("videoMetrics case carries sample")
    func videoMetricsCase() {
        let sample = FrameStatisticsSample(
            timestamp: 0.5, capturedFrameRate: 30,
            droppedFrames: 0, encodedFrameRate: 30,
            averageEncodingTime: 0.001, currentBitrate: 5_000_000,
            keyFrameInterval: 60, bufferLevel: 10)
        let event = MeteringEvent.videoMetrics(sample)
        if case .videoMetrics(let s) = event {
            #expect(s.capturedFrameRate == 30)
        } else {
            Issue.record("Expected videoMetrics")
        }
    }

    @Test("waveform case carries data")
    func waveformCase() {
        let data = WaveformData(
            timestamp: 0, duration: 0.1,
            bars: [0.5], minMax: [], sampleCount: 100)
        let event = MeteringEvent.waveform(data)
        if case .waveform(let w) = event {
            #expect(w.bars.count == 1)
        } else {
            Issue.record("Expected waveform")
        }
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let sample = AudioLevelSample(
            timestamp: 0, peakLevel: -6.0,
            rmsLevel: -12.0, channels: [])
        let event: any Sendable = MeteringEvent.audioLevel(sample)
        _ = event
    }
}
