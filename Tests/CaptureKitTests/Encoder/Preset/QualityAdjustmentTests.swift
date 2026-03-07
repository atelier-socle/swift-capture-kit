// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("QualityAdjustment")
struct QualityAdjustmentTests {

    @Test("stores from and to levels")
    func storesFromAndToLevels() {
        let adjustment = QualityAdjustment(from: .maximum, to: .high, reason: "test", direction: .reduced)
        #expect(adjustment.from == .maximum)
        #expect(adjustment.to == .high)
    }

    @Test("stores reason")
    func storesReason() {
        let adjustment = QualityAdjustment(from: .maximum, to: .high, reason: "test", direction: .reduced)
        #expect(adjustment.reason == "test")
    }

    @Test("stores direction")
    func storesDirection() {
        let adjustment = QualityAdjustment(from: .maximum, to: .high, reason: "test", direction: .reduced)
        #expect(adjustment.direction == .reduced)
    }

    @Test("Equatable conformance")
    func equatableConformance() {
        let adjustment1 = QualityAdjustment(from: .maximum, to: .high, reason: "test", direction: .reduced)
        let adjustment2 = QualityAdjustment(from: .maximum, to: .high, reason: "test", direction: .reduced)
        #expect(adjustment1 == adjustment2)
    }

    @Test("Sendable conformance")
    func sendableConformance() {
        let _: any Sendable = QualityAdjustment(from: .maximum, to: .high, reason: "", direction: .reduced)
    }
}
