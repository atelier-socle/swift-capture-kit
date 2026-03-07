// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("QualityDirection")
struct QualityDirectionTests {

    @Test("has two cases")
    func hasTwoCases() {
        #expect(QualityDirection.allCases.count == 2)
    }

    @Test("raw values are correct")
    func rawValuesAreCorrect() {
        #expect(QualityDirection.reduced.rawValue == "reduced")
        #expect(QualityDirection.restored.rawValue == "restored")
    }

    @Test("CaseIterable conformance")
    func caseIterableConformance() {
        for direction in QualityDirection.allCases {
            #expect(direction == .reduced || direction == .restored)
        }
    }
}
