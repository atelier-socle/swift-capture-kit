// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ScreenCaptureKitConfiguration")
struct ScreenCaptureKitConfigurationTests {

    @Test("default preset values")
    func defaultPresetValues() {
        let config = ScreenCaptureKitConfiguration.default
        #expect(config.showsCursor == true)
        #expect(config.capturesSystemAudio == false)
        #expect(config.capturesMicrophone == false)
        #expect(config.excludeOwnApp == true)
        #expect(config.scaleFactor == 2)
        #expect(config.captureHDR == false)
        #expect(config.presenterOverlay == false)
    }

    @Test("streaming preset has systemAudio enabled")
    func streamingPresetSystemAudio() {
        let config = ScreenCaptureKitConfiguration.streaming
        #expect(config.capturesSystemAudio == true)
    }

    @Test("streaming preset has scaleFactor 1")
    func streamingPresetScaleFactor() {
        let config = ScreenCaptureKitConfiguration.streaming
        #expect(config.scaleFactor == 1)
    }

    @Test("tutorial preset has microphone enabled")
    func tutorialPresetMicrophone() {
        let config = ScreenCaptureKitConfiguration.tutorial
        #expect(config.capturesMicrophone == true)
    }

    @Test("tutorial preset has systemAudio enabled")
    func tutorialPresetSystemAudio() {
        let config = ScreenCaptureKitConfiguration.tutorial
        #expect(config.capturesSystemAudio == true)
    }

    @Test("custom configuration stores all properties")
    func customConfiguration() {
        let config = ScreenCaptureKitConfiguration(
            showsCursor: false,
            capturesSystemAudio: true,
            capturesMicrophone: true,
            excludeOwnApp: false,
            scaleFactor: 1,
            captureHDR: true,
            presenterOverlay: true
        )
        #expect(config.showsCursor == false)
        #expect(config.capturesSystemAudio == true)
        #expect(config.capturesMicrophone == true)
        #expect(config.excludeOwnApp == false)
        #expect(config.scaleFactor == 1)
        #expect(config.captureHDR == true)
        #expect(config.presenterOverlay == true)
    }

    @Test("Equatable conformance with same values")
    func equatableSameValues() {
        let config1 = ScreenCaptureKitConfiguration.default
        let config2 = ScreenCaptureKitConfiguration()
        #expect(config1 == config2)
    }

    @Test("Equatable conformance with different values")
    func equatableDifferentValues() {
        let config1 = ScreenCaptureKitConfiguration.default
        let config2 = ScreenCaptureKitConfiguration.streaming
        #expect(config1 != config2)
    }

    @Test("showsCursor default is true")
    func showsCursorDefault() {
        let config = ScreenCaptureKitConfiguration()
        #expect(config.showsCursor == true)
    }

    @Test("captureHDR default is false")
    func captureHDRDefault() {
        let config = ScreenCaptureKitConfiguration()
        #expect(config.captureHDR == false)
    }
}
