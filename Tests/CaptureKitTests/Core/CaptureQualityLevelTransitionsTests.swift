// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing
@testable import CaptureKit

@Suite("CaptureQualityLevel Transitions")
struct CaptureQualityLevelTransitionsTests {

    // MARK: - Degraded

    @Test("degraded from maximum returns high")
    func degradedFromMaximumReturnsHigh() {
        let level = CaptureQualityLevel.maximum
        #expect(level.degraded == .high)
    }

    @Test("degraded from high returns medium")
    func degradedFromHighReturnsMedium() {
        let level = CaptureQualityLevel.high
        #expect(level.degraded == .medium)
    }

    @Test("degraded from medium returns low")
    func degradedFromMediumReturnsLow() {
        let level = CaptureQualityLevel.medium
        #expect(level.degraded == .low)
    }

    @Test("degraded from low returns minimum")
    func degradedFromLowReturnsMinimum() {
        let level = CaptureQualityLevel.low
        #expect(level.degraded == .minimum)
    }

    @Test("degraded from minimum returns nil")
    func degradedFromMinimumReturnsNil() {
        let level = CaptureQualityLevel.minimum
        #expect(level.degraded == nil)
    }

    // MARK: - Improved

    @Test("improved from minimum returns low")
    func improvedFromMinimumReturnsLow() {
        let level = CaptureQualityLevel.minimum
        #expect(level.improved == .low)
    }

    @Test("improved from low returns medium")
    func improvedFromLowReturnsMedium() {
        let level = CaptureQualityLevel.low
        #expect(level.improved == .medium)
    }

    @Test("improved from medium returns high")
    func improvedFromMediumReturnsHigh() {
        let level = CaptureQualityLevel.medium
        #expect(level.improved == .high)
    }

    @Test("improved from high returns maximum")
    func improvedFromHighReturnsMaximum() {
        let level = CaptureQualityLevel.high
        #expect(level.improved == .maximum)
    }

    @Test("improved from maximum returns nil")
    func improvedFromMaximumReturnsNil() {
        let level = CaptureQualityLevel.maximum
        #expect(level.improved == nil)
    }
}
