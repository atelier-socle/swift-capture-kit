// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ReplayKitConfiguration", .timeLimit(.minutes(1)))
struct ReplayKitConfigurationTests {

    @Test("default preset has all disabled")
    func defaultPresetValues() {
        let config = ReplayKitConfiguration.default
        #expect(config.isMicrophoneEnabled == false)
        #expect(config.isCameraEnabled == false)
        #expect(config.hdrEnabled == false)
    }

    @Test("gameplay preset has mic enabled")
    func gameplayPresetMicEnabled() {
        let config = ReplayKitConfiguration.gameplay
        #expect(config.isMicrophoneEnabled == true)
    }

    @Test("gameplay preset has camera disabled")
    func gameplayPresetCameraDisabled() {
        let config = ReplayKitConfiguration.gameplay
        #expect(config.isCameraEnabled == false)
    }

    @Test("tutorial preset has mic and camera enabled")
    func tutorialPresetValues() {
        let config = ReplayKitConfiguration.tutorial
        #expect(config.isMicrophoneEnabled == true)
        #expect(config.isCameraEnabled == true)
    }

    @Test("custom configuration stores all properties")
    func customConfiguration() {
        let config = ReplayKitConfiguration(
            isMicrophoneEnabled: true,
            isCameraEnabled: true,
            hdrEnabled: true
        )
        #expect(config.isMicrophoneEnabled == true)
        #expect(config.isCameraEnabled == true)
        #expect(config.hdrEnabled == true)
    }

    @Test("Equatable conformance with same values")
    func equatableSameValues() {
        let config1 = ReplayKitConfiguration(isMicrophoneEnabled: true)
        let config2 = ReplayKitConfiguration(isMicrophoneEnabled: true)
        #expect(config1 == config2)
    }

    @Test("Equatable conformance with different values")
    func equatableDifferentValues() {
        let config1 = ReplayKitConfiguration(isMicrophoneEnabled: true)
        let config2 = ReplayKitConfiguration(isMicrophoneEnabled: false)
        #expect(config1 != config2)
    }

    @Test("isMicrophoneEnabled default is false")
    func microphoneDefault() {
        let config = ReplayKitConfiguration()
        #expect(config.isMicrophoneEnabled == false)
    }
}
