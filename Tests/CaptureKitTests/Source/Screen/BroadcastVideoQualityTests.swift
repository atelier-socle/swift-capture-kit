// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("BroadcastVideoQuality", .timeLimit(.minutes(1)))
struct BroadcastVideoQualityTests {

    @Test("CaseIterable count is 3")
    func caseIterableCount() {
        #expect(BroadcastVideoQuality.allCases.count == 3)
    }

    @Test("rawValues are low, medium, and high")
    func rawValues() {
        #expect(BroadcastVideoQuality.low.rawValue == "low")
        #expect(BroadcastVideoQuality.medium.rawValue == "medium")
        #expect(BroadcastVideoQuality.high.rawValue == "high")
    }

    @Test("all cases exist")
    func allCasesExist() {
        let allCases = BroadcastVideoQuality.allCases
        #expect(allCases.contains(.low))
        #expect(allCases.contains(.medium))
        #expect(allCases.contains(.high))
    }
}
