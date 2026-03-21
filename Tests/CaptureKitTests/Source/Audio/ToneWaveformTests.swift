// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("ToneWaveform", .timeLimit(.minutes(1)))
struct ToneWaveformTests {

    @Test("all eight cases exist")
    func allEightCasesExist() {
        #expect(ToneWaveform.allCases.count == 8)
    }

    @Test("rawValue correctness")
    func rawValueCorrectness() {
        #expect(ToneWaveform.sine.rawValue == "sine")
        #expect(ToneWaveform.square.rawValue == "square")
        #expect(ToneWaveform.sawtooth.rawValue == "sawtooth")
        #expect(ToneWaveform.triangle.rawValue == "triangle")
        #expect(ToneWaveform.whiteNoise.rawValue == "whiteNoise")
        #expect(ToneWaveform.pinkNoise.rawValue == "pinkNoise")
        #expect(ToneWaveform.brownNoise.rawValue == "brownNoise")
        #expect(ToneWaveform.ebur128Calibration.rawValue == "ebur128Calibration")
    }

    @Test("cases can be initialized from rawValue")
    func initFromRawValue() {
        #expect(ToneWaveform(rawValue: "sine") == .sine)
        #expect(ToneWaveform(rawValue: "square") == .square)
        #expect(ToneWaveform(rawValue: "sawtooth") == .sawtooth)
        #expect(ToneWaveform(rawValue: "triangle") == .triangle)
        #expect(ToneWaveform(rawValue: "whiteNoise") == .whiteNoise)
        #expect(ToneWaveform(rawValue: "pinkNoise") == .pinkNoise)
        #expect(ToneWaveform(rawValue: "brownNoise") == .brownNoise)
        #expect(ToneWaveform(rawValue: "ebur128Calibration") == .ebur128Calibration)
        #expect(ToneWaveform(rawValue: "invalid") == nil)
    }
}
