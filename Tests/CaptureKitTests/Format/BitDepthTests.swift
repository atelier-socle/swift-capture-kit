// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("BitDepth")
struct BitDepthTests {

    @Test("rawValue correctness for all cases")
    func rawValues() {
        #expect(BitDepth.bit8.rawValue == 8)
        #expect(BitDepth.bit10.rawValue == 10)
        #expect(BitDepth.bit12.rawValue == 12)
        #expect(BitDepth.bit16.rawValue == 16)
    }

    @Test("CaseIterable count is 4")
    func caseIterableCount() {
        #expect(BitDepth.allCases.count == 4)
    }

    @Test("Comparable ordering: bit8 < bit10 < bit12 < bit16")
    func comparableOrdering() {
        #expect(BitDepth.bit8 < BitDepth.bit10)
        #expect(BitDepth.bit10 < BitDepth.bit12)
        #expect(BitDepth.bit12 < BitDepth.bit16)
    }

    @Test("Comparable: bit16 is not less than bit8")
    func comparableHighNotLessThanLow() {
        #expect(!(BitDepth.bit16 < BitDepth.bit8))
    }
}

@Suite("AudioBitDepth")
struct AudioBitDepthTests {

    @Test("All 5 cases exist with correct rawValues")
    func rawValues() {
        #expect(AudioBitDepth.int16.rawValue == "int16")
        #expect(AudioBitDepth.int24.rawValue == "int24")
        #expect(AudioBitDepth.int32.rawValue == "int32")
        #expect(AudioBitDepth.float32.rawValue == "float32")
        #expect(AudioBitDepth.float64.rawValue == "float64")
    }

    @Test("CaseIterable count is 5")
    func caseIterableCount() {
        #expect(AudioBitDepth.allCases.count == 5)
    }

    @Test("Cases can be initialized from rawValue")
    func initFromRawValue() {
        #expect(AudioBitDepth(rawValue: "float32") == .float32)
        #expect(AudioBitDepth(rawValue: "int24") == .int24)
        #expect(AudioBitDepth(rawValue: "invalid") == nil)
    }
}
