// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AdaptiveQualityManager — Edge Cases")
struct AdaptiveQualityManagerEdgeCaseTests {

    private func poorReport() -> StreamingTransportQuality {
        StreamingTransportQuality(score: 0.2, grade: .poor)
    }

    private func criticalReport() -> StreamingTransportQuality {
        StreamingTransportQuality(score: 0.05, grade: .critical)
    }

    private func goodReport() -> StreamingTransportQuality {
        StreamingTransportQuality(score: 0.8, grade: .good)
    }

    private func excellentReport() -> StreamingTransportQuality {
        StreamingTransportQuality(score: 0.95, grade: .excellent)
    }

    private func fairReport() -> StreamingTransportQuality {
        StreamingTransportQuality(score: 0.5, grade: .fair)
    }

    private func immediatePolicy() -> AdaptiveCapturePolicy {
        AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
    }

    private func responsivePolicy() -> AdaptiveCapturePolicy {
        AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .responsive)
    }

    @Test("No restoration when already at maximum")
    func noRestorationWhenAlreadyAtMaximum() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager()
        await manager.start()
        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(goodReport())
        let adjustment = await manager.processQualityReport(goodReport())
        #expect(adjustment == nil)
    }

    @Test("Quality history records all adjustments")
    func qualityHistoryTracksChanges() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        let history = await manager.qualityHistory
        #expect(history.count == 2)
        #expect(history[0].from == .maximum)
        #expect(history[1].from == .high)
    }

    @Test("Reset clears counters and restores maximum level")
    func resetClearsCountersAndRestoresMaximum() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        _ = await manager.processQualityReport(poorReport())
        await manager.reset()
        #expect(await manager.currentLevel == .maximum)
        #expect(await manager.consecutiveDegradationCount == 0)
        #expect(await manager.consecutiveImprovementCount == 0)
    }

    @Test("Fair quality report resets both counters")
    func fairQualityResetsBothCounters() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: responsivePolicy())
        await manager.start()
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.consecutiveDegradationCount == 1)
        let adj = await manager.processQualityReport(fairReport())
        #expect(adj == nil)
        #expect(await manager.consecutiveDegradationCount == 0)
    }

    @Test("QualityAdjustment conforms to Equatable")
    func qualityAdjustmentEquatable() {
        let adj1 = QualityAdjustment(
            from: .maximum, to: .high, reason: "test", direction: .reduced)
        let adj2 = QualityAdjustment(
            from: .maximum, to: .high, reason: "test", direction: .reduced)
        let adj3 = QualityAdjustment(
            from: .high, to: .medium, reason: "test", direction: .reduced)
        #expect(adj1 == adj2)
        #expect(adj1 != adj3)
    }

    @Test("QualityDirection has exactly two cases")
    func qualityDirectionAllCases() {
        #expect(QualityDirection.allCases.count == 2)
        #expect(QualityDirection.allCases.contains(.reduced))
        #expect(QualityDirection.allCases.contains(.restored))
    }

    @Test("Disabled policy prevents start from activating")
    func disabledPolicyPreventsActivation() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: .disabled)
        await manager.start()
        #expect(await manager.isActive == false)
    }

    @Test("History records both degradation and restoration")
    func historyRecordsBothDirections() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(goodReport())
        let history = await manager.qualityHistory
        #expect(history.count == 2)
        #expect(history[0].direction == .reduced)
        #expect(history[1].direction == .restored)
    }

    @Test("Excellent quality also counts as improvement")
    func excellentQualityCountsAsImprovement() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(excellentReport())
        _ = await manager.processQualityReport(excellentReport())
        let adj = await manager.processQualityReport(excellentReport())
        #expect(adj?.direction == .restored)
    }

    @Test("Alternating poor and good reports do not trigger with responsive policy")
    func alternatingReportsDoNotTrigger() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: responsivePolicy())
        await manager.start()
        for _ in 0..<5 {
            #expect(await manager.processQualityReport(poorReport()) == nil)
            #expect(await manager.processQualityReport(goodReport()) == nil)
        }
        #expect(await manager.currentLevel == .maximum)
    }

    @Test("Default policy uses responsive and fair minimum grade")
    func defaultPolicyConfiguration() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: .default)
        #expect(await manager.policy.responsiveness == .responsive)
        #expect(await manager.policy.minimumGrade == .fair)
    }

    @Test("Critical quality triggers degradation with immediate policy")
    func criticalQualityTriggersDegradation() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        let adj = await manager.processQualityReport(criticalReport())
        #expect(adj?.direction == .reduced)
    }

    @Test("Quality history entries include reason text")
    func qualityHistoryIncludesReason() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        _ = await manager.processQualityReport(poorReport())
        let history = await manager.qualityHistory
        #expect(history[0].reason.isEmpty == false)
    }
}
