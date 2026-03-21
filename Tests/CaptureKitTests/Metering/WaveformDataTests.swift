// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("WaveformData", .timeLimit(.minutes(1)))
struct WaveformDataTests {

    @Test("stores timestamp and duration")
    func storesValues() {
        let data = WaveformData(
            timestamp: 1.0, duration: 0.5,
            bars: [], minMax: [], sampleCount: 0)
        #expect(data.timestamp == 1.0)
        #expect(data.duration == 0.5)
    }

    @Test("bars array stores values")
    func barsArray() {
        let data = WaveformData(
            timestamp: 0, duration: 0.1,
            bars: [0.5, 0.8, 0.3], minMax: [], sampleCount: 100)
        #expect(data.bars.count == 3)
        #expect(data.bars[1] == 0.8)
    }

    @Test("minMax array stores buckets")
    func minMaxArray() {
        let bucket = WaveformBucket(min: -0.5, max: 0.5, rms: 0.3)
        let data = WaveformData(
            timestamp: 0, duration: 0.1,
            bars: [], minMax: [bucket], sampleCount: 256)
        #expect(data.minMax.count == 1)
        #expect(data.minMax[0].min == -0.5)
    }

    @Test("sampleCount stores value")
    func sampleCount() {
        let data = WaveformData(
            timestamp: 0, duration: 0.1,
            bars: [], minMax: [], sampleCount: 1024)
        #expect(data.sampleCount == 1024)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = WaveformData(
            timestamp: 0, duration: 0.1,
            bars: [0.5], minMax: [], sampleCount: 100)
        let b = WaveformData(
            timestamp: 0, duration: 0.1,
            bars: [0.5], minMax: [], sampleCount: 100)
        #expect(a == b)
    }

    @Test("different values are not equal")
    func notEqual() {
        let a = WaveformData(
            timestamp: 0, duration: 0.1,
            bars: [0.5], minMax: [], sampleCount: 100)
        let b = WaveformData(
            timestamp: 0, duration: 0.1,
            bars: [0.8], minMax: [], sampleCount: 100)
        #expect(a != b)
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let data: any Sendable = WaveformData(
            timestamp: 0, duration: 0, bars: [],
            minMax: [], sampleCount: 0)
        _ = data
    }

    @Test("empty waveform data")
    func emptyWaveform() {
        let data = WaveformData(
            timestamp: 0, duration: 0,
            bars: [], minMax: [], sampleCount: 0)
        #expect(data.bars.isEmpty)
        #expect(data.minMax.isEmpty)
    }
}
