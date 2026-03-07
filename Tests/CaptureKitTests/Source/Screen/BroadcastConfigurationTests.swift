// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("BroadcastConfiguration")
struct BroadcastConfigurationTests {

    @Test("appGroupID storage")
    func appGroupIDStorage() {
        let config = BroadcastConfiguration(appGroupID: "group.com.test")
        #expect(config.appGroupID == "group.com.test")
    }

    @Test("default maxBufferSize is 5_242_880")
    func defaultMaxBufferSize() {
        let config = BroadcastConfiguration(appGroupID: "group.com.test")
        #expect(config.maxBufferSize == 5_242_880)
    }

    @Test("custom maxBufferSize")
    func customMaxBufferSize() {
        let config = BroadcastConfiguration(appGroupID: "group.com.test", maxBufferSize: 10_485_760)
        #expect(config.maxBufferSize == 10_485_760)
    }

    @Test("capturesSystemAudio defaults to true")
    func capturesSystemAudioDefaultTrue() {
        let config = BroadcastConfiguration(appGroupID: "group.com.test")
        #expect(config.capturesSystemAudio == true)
    }

    @Test("capturesMicrophone defaults to false")
    func capturesMicrophoneDefaultFalse() {
        let config = BroadcastConfiguration(appGroupID: "group.com.test")
        #expect(config.capturesMicrophone == false)
    }

    @Test("videoQuality defaults to medium")
    func videoQualityDefaultMedium() {
        let config = BroadcastConfiguration(appGroupID: "group.com.test")
        #expect(config.videoQuality == .medium)
    }

    @Test("Equatable conformance")
    func equatableConformance() {
        let config1 = BroadcastConfiguration(appGroupID: "group.com.test")
        let config2 = BroadcastConfiguration(appGroupID: "group.com.test")
        let config3 = BroadcastConfiguration(appGroupID: "group.com.other")
        #expect(config1 == config2)
        #expect(config1 != config3)
    }

    @Test("BroadcastVideoQuality allCases count is 3")
    func broadcastVideoQualityAllCasesCount() {
        #expect(BroadcastVideoQuality.allCases.count == 3)
    }
}
