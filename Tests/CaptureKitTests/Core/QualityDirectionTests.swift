// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("QualityDirection", .timeLimit(.minutes(1)))
struct QualityDirectionTests {

    @Test("allCases has exactly two members")
    func allCasesHasTwoMembers() {
        #expect(QualityDirection.allCases.count == 2)
    }

    @Test("reduced rawValue is reduced")
    func reducedRawValue() {
        #expect(QualityDirection.reduced.rawValue == "reduced")
    }

    @Test("restored rawValue is restored")
    func restoredRawValue() {
        #expect(QualityDirection.restored.rawValue == "restored")
    }

    @Test("init from rawValue produces correct case")
    func initFromRawValue() {
        let reduced = QualityDirection(rawValue: "reduced")
        let restored = QualityDirection(rawValue: "restored")
        let invalid = QualityDirection(rawValue: "unknown")

        #expect(reduced == .reduced)
        #expect(restored == .restored)
        #expect(invalid == nil)
    }

    @Test("CaseIterable iteration covers all cases")
    func caseIterableIteration() {
        var seen: Set<String> = []
        for direction in QualityDirection.allCases {
            seen.insert(direction.rawValue)
        }
        #expect(seen.contains("reduced"))
        #expect(seen.contains("restored"))
        #expect(seen.count == 2)
    }
}
