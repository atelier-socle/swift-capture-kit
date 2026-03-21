// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("TorchMode", .timeLimit(.minutes(1)))
struct TorchModeTests {

    @Test("CaseIterable count is 3")
    func caseIterableCount() {
        #expect(TorchMode.allCases.count == 3)
    }

    @Test("rawValue matches expected strings")
    func rawValues() {
        #expect(TorchMode.off.rawValue == "off")
        #expect(TorchMode.on.rawValue == "on")
        #expect(TorchMode.auto.rawValue == "auto")
    }

    @Test("all cases exist")
    func allCasesExist() {
        let cases = TorchMode.allCases
        #expect(cases.contains(.off))
        #expect(cases.contains(.on))
        #expect(cases.contains(.auto))
    }
}
