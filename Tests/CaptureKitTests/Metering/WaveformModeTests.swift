// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("WaveformMode", .timeLimit(.minutes(1)))
struct WaveformModeTests {

    @Test("simple mode stores barCount")
    func simpleMode() {
        let mode = WaveformMode.simple(barCount: 50)
        if case .simple(let count) = mode {
            #expect(count == 50)
        } else {
            Issue.record("Expected simple mode")
        }
    }

    @Test("detailed mode stores samplesPerBucket")
    func detailedMode() {
        let mode = WaveformMode.detailed(samplesPerBucket: 256)
        if case .detailed(let samples) = mode {
            #expect(samples == 256)
        } else {
            Issue.record("Expected detailed mode")
        }
    }

    @Test("both mode stores both values")
    func bothMode() {
        let mode = WaveformMode.both(
            barCount: 50, samplesPerBucket: 256)
        if case .both(let bars, let samples) = mode {
            #expect(bars == 50)
            #expect(samples == 256)
        } else {
            Issue.record("Expected both mode")
        }
    }

    @Test("message preset is simple with 50 bars")
    func messagePreset() {
        #expect(WaveformMode.message == .simple(barCount: 50))
    }

    @Test("daw preset is detailed with 256 samples")
    func dawPreset() {
        #expect(
            WaveformMode.daw == .detailed(samplesPerBucket: 256))
    }

    @Test("disabled mode")
    func disabledMode() {
        #expect(WaveformMode.disabled == .disabled)
    }
}
