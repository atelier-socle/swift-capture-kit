// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CaptureSessionConfiguration")
struct CaptureSessionConfigurationTests {

    @Test("default preset values")
    func defaultPreset() {
        let config = CaptureSessionConfiguration.default
        #expect(config.automaticallyRequestPermissions == true)
        #expect(config.reconnectOnDeviceDisconnect == true)
        #expect(config.maxReconnectAttempts == 3)
        #expect(config.statisticsUpdateInterval == 1.0)
        #expect(config.adaptivePolicy == .default)
    }

    @Test("lowLatency preset values")
    func lowLatencyPreset() {
        let config = CaptureSessionConfiguration.lowLatency
        #expect(config.automaticallyRequestPermissions == true)
        #expect(config.reconnectOnDeviceDisconnect == false)
        #expect(config.maxReconnectAttempts == 0)
        #expect(config.statisticsUpdateInterval == 0.5)
        #expect(config.adaptivePolicy.enabled == true)
        #expect(config.adaptivePolicy.minimumGrade == .good)
        #expect(config.adaptivePolicy.responsiveness == .immediate)
    }

    @Test("highQuality preset values")
    func highQualityPreset() {
        let config = CaptureSessionConfiguration.highQuality
        #expect(config.automaticallyRequestPermissions == true)
        #expect(config.reconnectOnDeviceDisconnect == true)
        #expect(config.maxReconnectAttempts == 5)
        #expect(config.statisticsUpdateInterval == 2.0)
        #expect(config.adaptivePolicy.enabled == true)
        #expect(config.adaptivePolicy.minimumGrade == .excellent)
        #expect(config.adaptivePolicy.responsiveness == .conservative)
    }

    @Test("AdaptiveCapturePolicy default values")
    func adaptivePolicyDefault() {
        let policy = AdaptiveCapturePolicy.default
        #expect(policy.enabled == true)
        #expect(policy.minimumGrade == .fair)
        #expect(policy.responsiveness == .responsive)
    }

    @Test("AdaptiveCapturePolicy disabled values")
    func adaptivePolicyDisabled() {
        let policy = AdaptiveCapturePolicy.disabled
        #expect(policy.enabled == false)
        #expect(policy.minimumGrade == .critical)
        #expect(policy.responsiveness == .conservative)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = CaptureSessionConfiguration.default
        let b = CaptureSessionConfiguration.default
        #expect(a == b)

        let c = CaptureSessionConfiguration.lowLatency
        #expect(a != c)
    }

    @Test("Responsiveness CaseIterable count is three")
    func responsivenessCaseCount() {
        #expect(AdaptiveCapturePolicy.Responsiveness.allCases.count == 3)
    }
}
