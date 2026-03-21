// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("TestPattern", .timeLimit(.minutes(1)))
struct TestPatternTests {

    @Test("CaseIterable count is 10")
    func caseIterableCount() {
        #expect(TestPattern.allCases.count == 10)
    }

    @Test("rawValue matches expected strings")
    func rawValues() {
        #expect(TestPattern.smpteBars.rawValue == "smpteBars")
        #expect(TestPattern.smpteHD.rawValue == "smpteHD")
        #expect(TestPattern.ebu100.rawValue == "ebu100")
        #expect(TestPattern.ebu75.rawValue == "ebu75")
        #expect(TestPattern.grid.rawValue == "grid")
        #expect(TestPattern.checkerboard.rawValue == "checkerboard")
        #expect(TestPattern.grayRamp.rawValue == "grayRamp")
        #expect(TestPattern.colorChecker.rawValue == "colorChecker")
        #expect(TestPattern.zoneplate.rawValue == "zoneplate")
        #expect(TestPattern.countdown.rawValue == "countdown")
    }

    @Test("all cases exist")
    func allCasesExist() {
        let cases = TestPattern.allCases
        #expect(cases.contains(.smpteBars))
        #expect(cases.contains(.smpteHD))
        #expect(cases.contains(.ebu100))
        #expect(cases.contains(.ebu75))
        #expect(cases.contains(.grid))
        #expect(cases.contains(.checkerboard))
        #expect(cases.contains(.grayRamp))
        #expect(cases.contains(.colorChecker))
        #expect(cases.contains(.zoneplate))
        #expect(cases.contains(.countdown))
    }

    @Test("Sendable conformance allows use in Task")
    func sendableConformance() async {
        let pattern = TestPattern.smpteBars
        let result = await Task { pattern }.value
        #expect(result == .smpteBars)
    }
}
