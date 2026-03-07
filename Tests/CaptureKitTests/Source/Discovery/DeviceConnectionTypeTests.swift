// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("DeviceConnectionType")
struct DeviceConnectionTypeTests {

    @Test("all six cases exist")
    func allSixCasesExist() {
        #expect(DeviceConnectionType.allCases.count == 6)
    }

    @Test("rawValue correctness")
    func rawValueCorrectness() {
        #expect(DeviceConnectionType.builtIn.rawValue == "builtIn")
        #expect(DeviceConnectionType.usb.rawValue == "usb")
        #expect(DeviceConnectionType.thunderbolt.rawValue == "thunderbolt")
        #expect(DeviceConnectionType.bluetooth.rawValue == "bluetooth")
        #expect(DeviceConnectionType.continuityCamera.rawValue == "continuityCamera")
        #expect(DeviceConnectionType.wireless.rawValue == "wireless")
    }

    @Test("cases can be initialized from rawValue")
    func initFromRawValue() {
        #expect(DeviceConnectionType(rawValue: "builtIn") == .builtIn)
        #expect(DeviceConnectionType(rawValue: "usb") == .usb)
        #expect(DeviceConnectionType(rawValue: "thunderbolt") == .thunderbolt)
        #expect(DeviceConnectionType(rawValue: "bluetooth") == .bluetooth)
        #expect(DeviceConnectionType(rawValue: "continuityCamera") == .continuityCamera)
        #expect(DeviceConnectionType(rawValue: "wireless") == .wireless)
        #expect(DeviceConnectionType(rawValue: "invalid") == nil)
    }
}
