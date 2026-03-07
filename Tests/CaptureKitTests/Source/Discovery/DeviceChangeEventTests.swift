// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("DeviceChangeEvent")
struct DeviceChangeEventTests {

    @Test("audioDeviceConnected carries device info")
    func audioConnected() {
        let device = AudioDeviceInfo(
            id: "mic-1", name: "Test Mic",
            connectionType: .usb, inputChannelCount: 2,
            supportedSampleRates: [.rate44100])
        let event = DeviceChangeEvent.audioDeviceConnected(device)
        if case .audioDeviceConnected(let d) = event {
            #expect(d.id == "mic-1")
        } else {
            Issue.record("Expected audioDeviceConnected")
        }
    }

    @Test("audioDeviceDisconnected carries device ID")
    func audioDisconnected() {
        let event = DeviceChangeEvent.audioDeviceDisconnected("mic-1")
        if case .audioDeviceDisconnected(let id) = event {
            #expect(id == "mic-1")
        } else {
            Issue.record("Expected audioDeviceDisconnected")
        }
    }

    @Test("videoDeviceConnected carries device info")
    func videoConnected() {
        let device = VideoDeviceInfo(
            id: "cam-1", name: "Test Cam",
            connectionType: .usb)
        let event = DeviceChangeEvent.videoDeviceConnected(device)
        if case .videoDeviceConnected(let d) = event {
            #expect(d.id == "cam-1")
        } else {
            Issue.record("Expected videoDeviceConnected")
        }
    }

    @Test("videoDeviceDisconnected carries device ID")
    func videoDisconnected() {
        let event = DeviceChangeEvent.videoDeviceDisconnected("cam-1")
        if case .videoDeviceDisconnected(let id) = event {
            #expect(id == "cam-1")
        } else {
            Issue.record("Expected videoDeviceDisconnected")
        }
    }

    @Test("defaultAudioDeviceChanged carries optional device")
    func defaultAudioChanged() {
        let event = DeviceChangeEvent.defaultAudioDeviceChanged(nil)
        if case .defaultAudioDeviceChanged(let d) = event {
            #expect(d == nil)
        } else {
            Issue.record("Expected defaultAudioDeviceChanged")
        }
    }

    @Test("defaultVideoDeviceChanged carries optional device")
    func defaultVideoChanged() {
        let event = DeviceChangeEvent.defaultVideoDeviceChanged(nil)
        if case .defaultVideoDeviceChanged(let d) = event {
            #expect(d == nil)
        } else {
            Issue.record("Expected defaultVideoDeviceChanged")
        }
    }
}
