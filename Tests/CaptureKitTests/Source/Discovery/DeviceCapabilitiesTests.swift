// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("DeviceCapabilities", .timeLimit(.minutes(1)))
struct DeviceCapabilitiesTests {

    @Test("available returns non-empty set")
    func availableNonEmpty() {
        let caps = DeviceCapabilities.available()
        #expect(!caps.isEmpty)
    }

    @Test("isAvailable returns bool")
    func isAvailableReturnsBool() {
        _ = DeviceCapabilities.isAvailable(.multiCamera)
    }

    #if os(macOS)
        @Test("macOS has screenCaptureKit")
        func macOSScreenCapture() {
            #expect(DeviceCapabilities.isAvailable(.screenCaptureKit))
        }

        @Test("macOS has usbAudioInput")
        func macOSUSBAudio() {
            #expect(DeviceCapabilities.isAvailable(.usbAudioInput))
        }

        @Test("macOS has thunderbolt")
        func macOSThunderbolt() {
            #expect(DeviceCapabilities.isAvailable(.thunderbolt))
        }
    #endif
}
