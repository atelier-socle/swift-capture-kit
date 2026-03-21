// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("AudioMeterMode", .timeLimit(.minutes(1)))
struct AudioMeterModeTests {

    @Test("all 5 modes exist")
    func allCases() {
        #expect(AudioMeterMode.allCases.count == 5)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(AudioMeterMode.peak.rawValue == "peak")
        #expect(AudioMeterMode.rms.rawValue == "rms")
        #expect(AudioMeterMode.peakAndRMS.rawValue == "peakAndRMS")
        #expect(AudioMeterMode.loudness.rawValue == "loudness")
        #expect(AudioMeterMode.full.rawValue == "full")
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let mode: any Sendable = AudioMeterMode.full
        _ = mode
    }

    @Test("CaseIterable includes all modes")
    func caseIterable() {
        let modes = AudioMeterMode.allCases
        #expect(modes.contains(.peak))
        #expect(modes.contains(.full))
    }
}
