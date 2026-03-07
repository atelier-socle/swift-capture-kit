// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("VideoDeviceInfo")
struct VideoDeviceInfoTests {

    @Test("init stores all provided values")
    func initStoresAllValues() {
        let device = VideoDeviceInfo(
            id: "cam-1",
            name: "Front Camera",
            manufacturer: "Apple",
            modelID: "model-42",
            position: .front,
            deviceType: .trueDepth,
            connectionType: .builtIn,
            hasFlash: true,
            hasTorch: true,
            supportsCinematic: true,
            supportsDepthData: true
        )

        #expect(device.id == "cam-1")
        #expect(device.name == "Front Camera")
        #expect(device.manufacturer == "Apple")
        #expect(device.modelID == "model-42")
        #expect(device.position == .front)
        #expect(device.deviceType == .trueDepth)
        #expect(device.connectionType == .builtIn)
        #expect(device.hasFlash == true)
        #expect(device.hasTorch == true)
        #expect(device.supportsCinematic == true)
        #expect(device.supportsDepthData == true)
    }

    @Test("default values are correct")
    func defaultValues() {
        let device = VideoDeviceInfo(id: "cam-2", name: "Camera", connectionType: .usb)

        #expect(device.manufacturer == nil)
        #expect(device.modelID == nil)
        #expect(device.position == .unspecified)
        #expect(device.deviceType == .wideAngle)
        #expect(device.hasFlash == false)
        #expect(device.hasTorch == false)
        #expect(device.supportsCinematic == false)
        #expect(device.supportsDepthData == false)
    }

    @Test("Identifiable id returns the device id")
    func identifiableId() {
        let device = VideoDeviceInfo(id: "unique-123", name: "Camera", connectionType: .usb)
        #expect(device.id == "unique-123")
    }

    @Test("Hashable produces same hash for same values")
    func hashableSameValues() {
        let device1 = VideoDeviceInfo(id: "cam-1", name: "Camera", connectionType: .usb)
        let device2 = VideoDeviceInfo(id: "cam-1", name: "Camera", connectionType: .usb)
        #expect(device1.hashValue == device2.hashValue)
    }

    @Test("Equatable returns true for same values")
    func equatableSameValues() {
        let device1 = VideoDeviceInfo(id: "cam-1", name: "Camera", connectionType: .usb)
        let device2 = VideoDeviceInfo(id: "cam-1", name: "Camera", connectionType: .usb)
        #expect(device1 == device2)
    }

    @Test("different devices are not equal")
    func differentDevicesAreNotEqual() {
        let device1 = VideoDeviceInfo(id: "cam-1", name: "Camera A", connectionType: .usb)
        let device2 = VideoDeviceInfo(id: "cam-2", name: "Camera B", connectionType: .bluetooth)
        #expect(device1 != device2)
    }
}
