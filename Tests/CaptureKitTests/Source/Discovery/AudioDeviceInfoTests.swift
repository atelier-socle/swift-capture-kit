// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("AudioDeviceInfo", .timeLimit(.minutes(1)))
struct AudioDeviceInfoTests {

    @Test("init with all fields stores values")
    func initWithAllFields() {
        let info = AudioDeviceInfo(
            id: "dev-001",
            name: "Studio Mic",
            manufacturer: "Shure",
            modelID: "SM7B",
            connectionType: .usb,
            inputChannelCount: 1,
            supportedSampleRates: [.rate44100, .rate48000],
            isDefault: true
        )

        #expect(info.id == "dev-001")
        #expect(info.name == "Studio Mic")
        #expect(info.manufacturer == "Shure")
        #expect(info.modelID == "SM7B")
        #expect(info.connectionType == .usb)
        #expect(info.inputChannelCount == 1)
        #expect(info.supportedSampleRates == [.rate44100, .rate48000])
        #expect(info.isDefault == true)
    }

    @Test("Identifiable conformance uses id property")
    func identifiableConformance() {
        let info = AudioDeviceInfo(
            id: "unique-42",
            name: "Test Device",
            connectionType: .builtIn,
            inputChannelCount: 2,
            supportedSampleRates: [.rate48000]
        )

        #expect(info.id == "unique-42")
    }

    @Test("Hashable conformance: equal instances have same hash")
    func hashableEqualInstances() {
        let infoA = AudioDeviceInfo(
            id: "dev-1",
            name: "Mic",
            manufacturer: "Apple",
            modelID: "M1",
            connectionType: .builtIn,
            inputChannelCount: 2,
            supportedSampleRates: [.rate48000],
            isDefault: false
        )
        let infoB = AudioDeviceInfo(
            id: "dev-1",
            name: "Mic",
            manufacturer: "Apple",
            modelID: "M1",
            connectionType: .builtIn,
            inputChannelCount: 2,
            supportedSampleRates: [.rate48000],
            isDefault: false
        )

        #expect(infoA.hashValue == infoB.hashValue)
    }

    @Test("Hashable conformance: different instances have different hash")
    func hashableDifferentInstances() {
        let infoA = AudioDeviceInfo(
            id: "dev-1",
            name: "Mic A",
            connectionType: .usb,
            inputChannelCount: 1,
            supportedSampleRates: [.rate44100]
        )
        let infoB = AudioDeviceInfo(
            id: "dev-2",
            name: "Mic B",
            connectionType: .bluetooth,
            inputChannelCount: 2,
            supportedSampleRates: [.rate48000]
        )

        #expect(infoA.hashValue != infoB.hashValue)
    }

    @Test("default parameter values")
    func defaultParameterValues() {
        let info = AudioDeviceInfo(
            id: "dev-default",
            name: "Default Test",
            connectionType: .wireless,
            inputChannelCount: 1,
            supportedSampleRates: [.rate48000]
        )

        #expect(info.manufacturer == nil)
        #expect(info.modelID == nil)
        #expect(info.isDefault == false)
    }
}
