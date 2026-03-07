// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AdaptiveQualityManager — Core")
struct AdaptiveQualityManagerCoreTests {

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

    private func immediatePolicy(
        minimumGrade: QualityGrade = .fair
    ) -> AdaptiveCapturePolicy {
        AdaptiveCapturePolicy(
            enabled: true,
            minimumGrade: minimumGrade,
            responsiveness: .immediate
        )
    }

    private func responsivePolicy(
        minimumGrade: QualityGrade = .fair
    ) -> AdaptiveCapturePolicy {
        AdaptiveCapturePolicy(
            enabled: true,
            minimumGrade: minimumGrade,
            responsiveness: .responsive
        )
    }

    private func conservativePolicy(
        minimumGrade: QualityGrade = .fair
    ) -> AdaptiveCapturePolicy {
        AdaptiveCapturePolicy(
            enabled: true,
            minimumGrade: minimumGrade,
            responsiveness: .conservative
        )
    }

    @Test("Init stores the provided policy")
    func initStoresPolicy() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let policy = immediatePolicy(minimumGrade: .poor)
        let manager = AdaptiveQualityManager(policy: policy)
        let stored = await manager.policy
        #expect(stored.enabled == true)
        #expect(stored.minimumGrade == .poor)
        #expect(stored.responsiveness == .immediate)
    }

    @Test("Start sets isActive to true")
    func startSetsIsActive() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager()
        await manager.start()
        #expect(await manager.isActive == true)
    }

    @Test("Stop sets isActive to false")
    func stopSetsIsActiveFalse() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager()
        await manager.start()
        await manager.stop()
        #expect(await manager.isActive == false)
    }

    @Test("Manager is not active initially")
    func notActiveInitially() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager()
        #expect(await manager.isActive == false)
    }

    @Test("Current level is maximum after start")
    func currentLevelMaximumAfterStart() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager()
        await manager.start()
        #expect(await manager.currentLevel == .maximum)
    }

    @Test("processQualityReport returns nil when not active")
    func processReturnsNilWhenNotActive() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        let adjustment = await manager.processQualityReport(poorReport())
        #expect(adjustment == nil)
    }

    @Test("processQualityReport returns nil when policy disabled")
    func processReturnsNilWhenPolicyDisabled() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: .disabled)
        await manager.start()
        let adjustment = await manager.processQualityReport(poorReport())
        #expect(adjustment == nil)
    }

    @Test("processQualityReport returns nil for good quality at maximum")
    func processReturnsNilForGoodQualityAtMaximum() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        let adjustment = await manager.processQualityReport(goodReport())
        #expect(adjustment == nil)
    }

    @Test("Immediate responsiveness triggers degradation on single poor report")
    func degradationWithImmediateResponsiveness() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        let adjustment = await manager.processQualityReport(poorReport())
        #expect(adjustment != nil)
        #expect(adjustment?.direction == .reduced)
        #expect(await manager.currentLevel == .high)
    }

    @Test("Responsive responsiveness requires two poor reports")
    func degradationWithResponsiveResponsiveness() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: responsivePolicy())
        await manager.start()
        let first = await manager.processQualityReport(poorReport())
        #expect(first == nil)
        let second = await manager.processQualityReport(poorReport())
        #expect(second != nil)
        #expect(await manager.currentLevel == .high)
    }

    @Test("Conservative responsiveness requires three poor reports")
    func degradationWithConservativeResponsiveness() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: conservativePolicy())
        await manager.start()
        #expect(await manager.processQualityReport(poorReport()) == nil)
        #expect(await manager.processQualityReport(poorReport()) == nil)
        let third = await manager.processQualityReport(poorReport())
        #expect(third != nil)
        #expect(await manager.currentLevel == .high)
    }

    @Test("Full degradation chain from maximum to minimum")
    func fullDegradationChain() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .high)
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .medium)
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .low)
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .minimum)
    }

    @Test("No further degradation at minimum")
    func noFurtherDegradationAtMinimum() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        for _ in 0..<4 { _ = await manager.processQualityReport(poorReport()) }
        #expect(await manager.currentLevel == .minimum)
        let adjustment = await manager.processQualityReport(poorReport())
        #expect(adjustment == nil)
    }

    @Test("Quality restores after three consecutive good reports")
    func qualityRestorationAfterThreeGoodReports() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let manager = AdaptiveQualityManager(policy: immediatePolicy())
        await manager.start()
        _ = await manager.processQualityReport(poorReport())
        #expect(await manager.currentLevel == .high)
        _ = await manager.processQualityReport(goodReport())
        _ = await manager.processQualityReport(goodReport())
        let third = await manager.processQualityReport(goodReport())
        #expect(third?.direction == .restored)
        #expect(await manager.currentLevel == .maximum)
    }
}
