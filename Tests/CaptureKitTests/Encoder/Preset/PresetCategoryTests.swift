// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("PresetCategory", .timeLimit(.minutes(1)))
struct PresetCategoryTests {

    @Test("all 8 categories exist")
    func allEightCategoriesExist() {
        #expect(PresetCategory.allCases.count == 8)
    }

    @Test("raw values are strings")
    func rawValuesAreStrings() {
        #expect(PresetCategory.streaming.rawValue == "streaming")
    }

    @Test("CaseIterable conformance")
    func caseIterableConformance() {
        let allCases = PresetCategory.allCases
        #expect(allCases.count > 0)
    }

    @Test("Sendable conformance")
    func sendableConformance() {
        let _: any Sendable = PresetCategory.streaming
    }
}
