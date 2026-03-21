// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("DeviceCapability", .timeLimit(.minutes(1)))
struct DeviceCapabilityTests {

    @Test("all 8 capabilities exist")
    func allCases() {
        #expect(DeviceCapability.allCases.count == 8)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(DeviceCapability.usbAudioInput.rawValue == "usbAudioInput")
        #expect(DeviceCapability.externalCamera.rawValue == "externalCamera")
        #expect(DeviceCapability.stageManager.rawValue == "stageManager")
        #expect(DeviceCapability.thunderbolt.rawValue == "thunderbolt")
        #expect(DeviceCapability.pencilInput.rawValue == "pencilInput")
        #expect(DeviceCapability.multiCamera.rawValue == "multiCamera")
        #expect(DeviceCapability.spatialAudio.rawValue == "spatialAudio")
        #expect(DeviceCapability.screenCaptureKit.rawValue == "screenCaptureKit")
    }

    @Test("CaseIterable includes all capabilities")
    func caseIterable() {
        let caps = DeviceCapability.allCases
        #expect(caps.contains(.usbAudioInput))
        #expect(caps.contains(.spatialAudio))
        #expect(caps.contains(.screenCaptureKit))
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let cap: any Sendable = DeviceCapability.multiCamera
        _ = cap
    }
}
