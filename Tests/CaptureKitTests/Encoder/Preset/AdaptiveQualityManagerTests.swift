// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AdaptiveQualityManager")
struct AdaptiveQualityManagerTests {

    // MARK: - Helpers

    private func poorReport() -> StreamingTransportQuality {
        StreamingTransportQuality(score: 0.2, grade: .poor)
    }

    private func goodReport() -> StreamingTransportQuality {
        StreamingTransportQuality(score: 0.8, grade: .good)
    }

    private func fairReport() -> StreamingTransportQuality {
        StreamingTransportQuality(score: 0.5, grade: .fair)
    }

    // MARK: - Initialization

    @Test("Starts at maximum quality")
    func startsAtMaximumQuality() async {
        let manager = AdaptiveQualityManager()
        #expect(await manager.currentLevel == .maximum)
    }

    @Test("Is not active initially")
    func isNotActiveInitially() async {
        let manager = AdaptiveQualityManager()
        #expect(await manager.isActive == false)
    }

    @Test("Start sets isActive")
    func startSetsIsActive() async {
        let manager = AdaptiveQualityManager()
        await manager.start()
        #expect(await manager.isActive == true)
    }

    @Test("Disabled policy does not activate")
    func disabledPolicyDoesNotActivate() async {
        let manager = AdaptiveQualityManager(policy: .disabled)
        await manager.start()
        #expect(await manager.isActive == false)
    }

    // MARK: - Degradation

    @Test("Single poor report with immediate responsiveness reduces quality")
    func singlePoorReportImmediateReduces() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        let adjustment = await manager.processQualityReport(poorReport())
        #expect(adjustment != nil)
        #expect(adjustment?.direction == .reduced)
        #expect(await manager.currentLevel == .high)
    }

    @Test("Single poor report with conservative responsiveness does not reduce")
    func singlePoorReportConservativeNoReduce() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .conservative)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        let adjustment = await manager.processQualityReport(poorReport())
        #expect(adjustment == nil)
        #expect(await manager.currentLevel == .maximum)
    }

    @Test("Two poor reports with responsive policy reduces quality")
    func twoPoorReportsResponsiveReduces() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .responsive)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        let first = await manager.processQualityReport(poorReport())
        #expect(first == nil)

        let second = await manager.processQualityReport(poorReport())
        #expect(second != nil)
        #expect(second?.direction == .reduced)
    }

    @Test("Three poor reports with conservative policy reduces quality")
    func threePoorReportsConservativeReduces() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .conservative)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        let first = await manager.processQualityReport(poorReport())
        #expect(first == nil)

        let second = await manager.processQualityReport(poorReport())
        #expect(second == nil)

        let third = await manager.processQualityReport(poorReport())
        #expect(third != nil)
        #expect(third?.direction == .reduced)
    }

    @Test("Degradation goes maximum to high to medium to low to minimum")
    func degradationChain() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        let adj1 = await manager.processQualityReport(poorReport())
        #expect(adj1?.to == .high)
        #expect(await manager.currentLevel == .high)

        let adj2 = await manager.processQualityReport(poorReport())
        #expect(adj2?.to == .medium)
        #expect(await manager.currentLevel == .medium)

        let adj3 = await manager.processQualityReport(poorReport())
        #expect(adj3?.to == .low)
        #expect(await manager.currentLevel == .low)

        let adj4 = await manager.processQualityReport(poorReport())
        #expect(adj4?.to == .minimum)
        #expect(await manager.currentLevel == .minimum)
    }

    @Test("At minimum quality further degradation returns nil")
    func atMinimumFurtherDegradationReturnsNil() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        // Reduce all the way to minimum
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .minimum)

        let adjustment = await manager.processQualityReport(poorReport())
        #expect(adjustment == nil)
    }

    @Test("Degradation resets consecutive count")
    func degradationResetsConsecutiveCount() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.consecutiveDegradationCount == 0)
    }

    // MARK: - Recovery

    @Test("Three good reports restore quality one level")
    func threeGoodReportsRestoreOneLevel() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        // Degrade to low
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .low)

        // Three good reports to restore one level
        let first = await manager.processQualityReport(goodReport())
        #expect(first == nil)
        let second = await manager.processQualityReport(goodReport())
        #expect(second == nil)
        let third = await manager.processQualityReport(goodReport())
        #expect(third != nil)
        #expect(third?.direction == .restored)
        #expect(await manager.currentLevel == .medium)
    }

    @Test("Recovery goes minimum to low to medium to high to maximum")
    func recoveryChain() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        // Degrade to minimum
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .minimum)

        // Recover step by step
        for expectedLevel: CaptureQualityLevel in [.low, .medium, .high, .maximum] {
            _ = await manager.processQualityReport(goodReport())
            _ = await manager.processQualityReport(goodReport())
            let adjustment = await manager.processQualityReport(goodReport())
            #expect(adjustment != nil)
            #expect(adjustment?.to == expectedLevel)
            #expect(adjustment?.direction == .restored)
        }

        #expect(await manager.currentLevel == .maximum)
    }

    @Test("At maximum quality recovery returns nil")
    func atMaximumRecoveryReturnsNil() async {
        let manager = AdaptiveQualityManager()
        await manager.start()

        // Already at maximum, good reports should not trigger adjustment
        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(goodReport())
        let adjustment = await manager.processQualityReport(goodReport())
        #expect(adjustment == nil)
    }

    @Test("Recovery resets consecutive improvement count")
    func recoveryResetsImprovementCount() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        // Degrade to high
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .high)

        // Recover with 3 good reports
        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(goodReport())

        #expect(await manager.consecutiveImprovementCount == 0)
    }

    @Test("Recovery is always conservative requiring three signals")
    func recoveryAlwaysRequiresThreeSignals() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        // Degrade to high
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .high)

        // Even with immediate policy, recovery needs 3 good reports
        let first = await manager.processQualityReport(goodReport())
        #expect(first == nil)
        let second = await manager.processQualityReport(goodReport())
        #expect(second == nil)
        let third = await manager.processQualityReport(goodReport())
        #expect(third != nil)
        #expect(third?.direction == .restored)
    }

    // MARK: - Mixed Signals

    @Test("Good report resets degradation counter")
    func goodReportResetsDegradationCounter() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .responsive)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(goodReport())
        #expect(await manager.consecutiveDegradationCount == 0)
    }

    @Test("Poor report resets improvement counter")
    func poorReportResetsImprovementCounter() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        // Degrade first so good reports are meaningful
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .high)

        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.consecutiveImprovementCount == 0)
    }

    @Test("Fair report resets both counters")
    func fairReportResetsBothCounters() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .responsive)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(fairReport())
        #expect(await manager.consecutiveDegradationCount == 0)
        #expect(await manager.consecutiveImprovementCount == 0)
    }

    @Test("Alternating poor and good does not trigger change")
    func alternatingDoesNotTriggerChange() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .responsive)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        for _ in 0..<6 {
            let adj1 = await manager.processQualityReport(poorReport())
            #expect(adj1 == nil)
            let adj2 = await manager.processQualityReport(goodReport())
            #expect(adj2 == nil)
        }

        #expect(await manager.currentLevel == .maximum)
    }

    // MARK: - History & Edge Cases

    @Test("Quality changes recorded in history")
    func qualityChangesRecordedInHistory() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())

        let history = await manager.qualityHistory
        #expect(history.count == 2)
    }

    @Test("History includes direction")
    func historyIncludesDirection() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        // Degrade
        _ = await manager.processQualityReport(poorReport())
        let historyAfterDegrade = await manager.qualityHistory
        #expect(historyAfterDegrade.last?.direction == .reduced)

        // Recover
        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(goodReport())
        let historyAfterRestore = await manager.qualityHistory
        #expect(historyAfterRestore.last?.direction == .restored)
    }

    @Test("Reset clears to maximum")
    func resetClearsToMaximum() async {
        let policy = AdaptiveCapturePolicy(enabled: true, minimumGrade: .fair, responsiveness: .immediate)
        let manager = AdaptiveQualityManager(policy: policy)
        await manager.start()

        _ = await manager.processQualityReport(poorReport())
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .medium)

        await manager.reset()
        #expect(await manager.currentLevel == .maximum)
    }

    @Test("ProcessQualityReport with disabled policy returns nil")
    func processWithDisabledPolicyReturnsNil() async {
        let manager = AdaptiveQualityManager(policy: .disabled)
        await manager.start()

        let adjustment = await manager.processQualityReport(poorReport())
        #expect(adjustment == nil)
    }

    @Test("ProcessQualityReport when not active returns nil")
    func processWhenNotActiveReturnsNil() async {
        let manager = AdaptiveQualityManager()
        // Do not call start()

        let adjustment = await manager.processQualityReport(poorReport())
        #expect(adjustment == nil)
    }
}
