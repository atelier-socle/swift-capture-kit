// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CaptureQualityLevel Extensions")
struct CaptureQualityLevelExtensionTests {

    @Test("maximum degraded is high")
    func maximumDegradedIsHigh() {
        #expect(CaptureQualityLevel.maximum.degraded == .high)
    }

    @Test("minimum degraded is nil")
    func minimumDegradedIsNil() {
        #expect(CaptureQualityLevel.minimum.degraded == nil)
    }

    @Test("minimum improved is low")
    func minimumImprovedIsLow() {
        #expect(CaptureQualityLevel.minimum.improved == .low)
    }

    @Test("maximum improved is nil")
    func maximumImprovedIsNil() {
        #expect(CaptureQualityLevel.maximum.improved == nil)
    }

    @Test("full degradation chain")
    func fullDegradationChain() {
        var level: CaptureQualityLevel? = .maximum
        var steps = 0
        while let current = level, let next = current.degraded {
            level = next
            steps += 1
        }
        #expect(steps == 4)
    }

    @Test("full improvement chain")
    func fullImprovementChain() {
        var level: CaptureQualityLevel? = .minimum
        var steps = 0
        while let current = level, let next = current.improved {
            level = next
            steps += 1
        }
        #expect(steps == 4)
    }
}
