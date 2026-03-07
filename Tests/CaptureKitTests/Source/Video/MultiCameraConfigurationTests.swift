// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("MultiCameraConfiguration")
struct MultiCameraConfigurationTests {

    private func makeDevice(id: String = "dev-1", name: String = "Camera") -> VideoDeviceInfo {
        VideoDeviceInfo(id: id, name: name, connectionType: .usb)
    }

    @Test("MultiCameraInput id combines device id and label")
    func inputIdCombinesDeviceIdAndLabel() {
        let device = makeDevice(id: "cam-42")
        let input = MultiCameraInput(device: device, label: "host")
        #expect(input.id == "cam-42-host")
    }

    @Test("MultiCameraInput stores device and label")
    func inputStoresDeviceAndLabel() {
        let device = makeDevice(id: "cam-1", name: "Front Camera")
        let input = MultiCameraInput(device: device, label: "guest-1")
        #expect(input.device == device)
        #expect(input.label == "guest-1")
    }

    @Test("MultiCameraInput default configuration is .default")
    func inputDefaultConfiguration() {
        let device = makeDevice()
        let input = MultiCameraInput(device: device, label: "main")
        #expect(input.configuration == .default)
    }

    @Test("MultiCameraConfiguration stores cameras")
    func configurationStoresCameras() {
        let input1 = MultiCameraInput(device: makeDevice(id: "a"), label: "host")
        let input2 = MultiCameraInput(device: makeDevice(id: "b"), label: "guest")
        let config = MultiCameraConfiguration(cameras: [input1, input2])
        #expect(config.cameras.count == 2)
        #expect(config.cameras[0].id == "a-host")
        #expect(config.cameras[1].id == "b-guest")
    }

    @Test("validate passes with 2 or more cameras")
    func validatePassesWithTwoOrMoreCameras() throws {
        let input1 = MultiCameraInput(device: makeDevice(id: "a"), label: "host")
        let input2 = MultiCameraInput(device: makeDevice(id: "b"), label: "guest")
        let config = MultiCameraConfiguration(cameras: [input1, input2])
        #expect(throws: Never.self) {
            try config.validate()
        }
    }

    @Test("validate throws with 0 cameras")
    func validateThrowsWithZeroCameras() {
        let config = MultiCameraConfiguration(cameras: [])
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws with 1 camera")
    func validateThrowsWithOneCamera() {
        let input = MultiCameraInput(device: makeDevice(), label: "solo")
        let config = MultiCameraConfiguration(cameras: [input])
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("requireMultiCam defaults to true")
    func requireMultiCamDefaultsToTrue() {
        let config = MultiCameraConfiguration(cameras: [])
        #expect(config.requireMultiCam == true)
    }
}
