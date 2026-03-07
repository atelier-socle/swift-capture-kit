// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("SpatialCaptureMode")
struct SpatialCaptureModeTests {

    @Test("CaseIterable count is 2")
    func caseIterableCount() {
        #expect(SpatialCaptureMode.allCases.count == 2)
    }

    @Test("rawValue matches expected strings")
    func rawValues() {
        #expect(SpatialCaptureMode.stereoscopic.rawValue == "stereoscopic")
        #expect(SpatialCaptureMode.monoFallback.rawValue == "monoFallback")
    }

    @Test("all cases exist")
    func allCasesExist() {
        let cases = SpatialCaptureMode.allCases
        #expect(cases.contains(.stereoscopic))
        #expect(cases.contains(.monoFallback))
    }
}
