// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("PixelFormat", .timeLimit(.minutes(1)))
struct PixelFormatTests {

    @Test("CaseIterable count is 6")
    func caseIterableCount() {
        #expect(PixelFormat.allCases.count == 6)
    }

    @Test("All 6 cases exist with correct rawValues")
    func rawValues() {
        #expect(PixelFormat.nv12.rawValue == "nv12")
        #expect(PixelFormat.bgra.rawValue == "bgra")
        #expect(PixelFormat.p210.rawValue == "p210")
        #expect(PixelFormat.p010.rawValue == "p010")
        #expect(PixelFormat.argb.rawValue == "argb")
        #expect(PixelFormat.yuvs.rawValue == "yuvs")
    }

    @Test("Cases can be initialized from rawValue")
    func initFromRawValue() {
        #expect(PixelFormat(rawValue: "nv12") == .nv12)
        #expect(PixelFormat(rawValue: "bgra") == .bgra)
        #expect(PixelFormat(rawValue: "invalid") == nil)
    }

    @Test("allCases contains all expected formats")
    func allCasesContainsExpected() {
        let expected: [PixelFormat] = [.nv12, .bgra, .p210, .p010, .argb, .yuvs]
        for format in expected {
            #expect(PixelFormat.allCases.contains(format))
        }
    }
}
