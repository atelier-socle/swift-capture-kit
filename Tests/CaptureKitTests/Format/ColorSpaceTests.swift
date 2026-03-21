// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("ColorSpace", .timeLimit(.minutes(1)))
struct ColorSpaceTests {

    @Test("CaseIterable count is 8")
    func caseIterableCount() {
        #expect(ColorSpace.allCases.count == 8)
    }

    @Test("All 8 cases exist with correct rawValues")
    func rawValues() {
        #expect(ColorSpace.srgb.rawValue == "srgb")
        #expect(ColorSpace.displayP3.rawValue == "displayP3")
        #expect(ColorSpace.bt709.rawValue == "bt709")
        #expect(ColorSpace.bt2020.rawValue == "bt2020")
        #expect(ColorSpace.bt2100PQ.rawValue == "bt2100PQ")
        #expect(ColorSpace.bt2100HLG.rawValue == "bt2100HLG")
        #expect(ColorSpace.dcip3.rawValue == "dcip3")
        #expect(ColorSpace.adobeRGB.rawValue == "adobeRGB")
    }

    @Test("Cases can be initialized from rawValue")
    func initFromRawValue() {
        #expect(ColorSpace(rawValue: "bt709") == .bt709)
        #expect(ColorSpace(rawValue: "displayP3") == .displayP3)
        #expect(ColorSpace(rawValue: "invalid") == nil)
    }

    @Test("allCases contains all expected color spaces")
    func allCasesContainsExpected() {
        let expected: [ColorSpace] = [
            .srgb, .displayP3, .bt709, .bt2020,
            .bt2100PQ, .bt2100HLG, .dcip3, .adobeRGB
        ]
        for space in expected {
            #expect(ColorSpace.allCases.contains(space))
        }
    }
}
