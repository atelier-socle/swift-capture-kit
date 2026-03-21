// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("DynamicRange", .timeLimit(.minutes(1)))
struct DynamicRangeTests {

    @Test("CaseIterable count is 5")
    func caseIterableCount() {
        #expect(DynamicRange.allCases.count == 5)
    }

    @Test("All 5 cases exist with correct rawValues")
    func rawValues() {
        #expect(DynamicRange.sdr.rawValue == "sdr")
        #expect(DynamicRange.hdr10.rawValue == "hdr10")
        #expect(DynamicRange.hdr10Plus.rawValue == "hdr10Plus")
        #expect(DynamicRange.dolbyVision.rawValue == "dolbyVision")
        #expect(DynamicRange.hlg.rawValue == "hlg")
    }

    @Test("Cases can be initialized from rawValue")
    func initFromRawValue() {
        #expect(DynamicRange(rawValue: "sdr") == .sdr)
        #expect(DynamicRange(rawValue: "dolbyVision") == .dolbyVision)
        #expect(DynamicRange(rawValue: "invalid") == nil)
    }

    @Test("allCases contains all expected ranges")
    func allCasesContainsExpected() {
        let expected: [DynamicRange] = [.sdr, .hdr10, .hdr10Plus, .dolbyVision, .hlg]
        for range in expected {
            #expect(DynamicRange.allCases.contains(range))
        }
    }
}
