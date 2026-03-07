// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("VideoBitrateMode")
struct VideoBitrateModeTests {
    @Test("all cases are available")
    func allCases() {
        #expect(VideoBitrateMode.allCases.count == 4)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(VideoBitrateMode.constant.rawValue == "constant")
        #expect(VideoBitrateMode.average.rawValue == "average")
        #expect(VideoBitrateMode.variable.rawValue == "variable")
        #expect(VideoBitrateMode.capped.rawValue == "capped")
    }

    @Test("is Sendable")
    func isSendable() {
        let mode: any Sendable = VideoBitrateMode.constant
        #expect(mode is VideoBitrateMode)
    }

    @Test("CaseIterable includes all modes")
    func caseIterable() {
        let cases = VideoBitrateMode.allCases
        #expect(cases.contains(.constant))
        #expect(cases.contains(.average))
        #expect(cases.contains(.variable))
        #expect(cases.contains(.capped))
    }
}
