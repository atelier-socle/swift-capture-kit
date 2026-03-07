// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CameraPosition")
struct CameraPositionTests {

    @Test("CaseIterable count is 3")
    func caseIterableCount() {
        #expect(CameraPosition.allCases.count == 3)
    }

    @Test("rawValue matches expected strings")
    func rawValues() {
        #expect(CameraPosition.front.rawValue == "front")
        #expect(CameraPosition.back.rawValue == "back")
        #expect(CameraPosition.unspecified.rawValue == "unspecified")
    }

    @Test("Sendable conformance allows use in Task")
    func sendableConformance() async {
        let position = CameraPosition.front
        let result = await Task { position }.value
        #expect(result == .front)
    }

    @Test("all cases exist")
    func allCasesExist() {
        let cases = CameraPosition.allCases
        #expect(cases.contains(.front))
        #expect(cases.contains(.back))
        #expect(cases.contains(.unspecified))
    }
}
