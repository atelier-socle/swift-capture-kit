// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("DeviceDiscovery")
struct DeviceDiscoveryTests {

    @Test("initially empty device lists")
    func initiallyEmpty() async {
        let discovery = DeviceDiscovery()
        #expect(await discovery.audioDevices.isEmpty)
        #expect(await discovery.videoDevices.isEmpty)
    }

    @Test("is not monitoring initially")
    func notMonitoringInitially() async {
        let discovery = DeviceDiscovery()
        #expect(await discovery.isMonitoring == false)
    }

    @Test("startMonitoring sets isMonitoring")
    func startMonitoring() async {
        let discovery = DeviceDiscovery()
        await discovery.startMonitoring()
        #expect(await discovery.isMonitoring == true)
    }

    @Test("startMonitoring when already monitoring is no-op")
    func startMonitoringIdempotent() async {
        let discovery = DeviceDiscovery()
        await discovery.startMonitoring()
        await discovery.startMonitoring()
        #expect(await discovery.isMonitoring == true)
    }

    @Test("stopMonitoring clears isMonitoring")
    func stopMonitoring() async {
        let discovery = DeviceDiscovery()
        await discovery.startMonitoring()
        await discovery.stopMonitoring()
        #expect(await discovery.isMonitoring == false)
    }

    @Test("defaultAudioDevice is nil when empty")
    func defaultAudioDeviceNil() async {
        let discovery = DeviceDiscovery()
        #expect(await discovery.defaultAudioDevice == nil)
    }

    @Test("defaultVideoDevice is nil when empty")
    func defaultVideoDeviceNil() async {
        let discovery = DeviceDiscovery()
        #expect(await discovery.defaultVideoDevice == nil)
    }

    @Test("simulateDeviceConnected adds to list")
    func simulateConnected() async {
        let discovery = DeviceDiscovery()
        let device = AudioDeviceInfo(
            id: "mic-1", name: "Test Mic",
            connectionType: .usb, inputChannelCount: 2,
            supportedSampleRates: [.rate44100])
        await discovery.simulateDeviceConnected(device)
        #expect(await discovery.audioDevices.count == 1)
    }

    @Test("simulateDeviceDisconnected removes from list")
    func simulateDisconnected() async {
        let discovery = DeviceDiscovery()
        let device = AudioDeviceInfo(
            id: "mic-1", name: "Test Mic",
            connectionType: .usb, inputChannelCount: 2,
            supportedSampleRates: [.rate44100])
        await discovery.simulateDeviceConnected(device)
        await discovery.simulateDeviceDisconnected(
            audioDeviceID: "mic-1")
        #expect(await discovery.audioDevices.isEmpty)
    }

    @Test("simulateVideoDeviceConnected adds to list")
    func simulateVideoConnected() async {
        let discovery = DeviceDiscovery()
        let device = VideoDeviceInfo(
            id: "cam-1", name: "Test Cam",
            connectionType: .usb)
        await discovery.simulateVideoDeviceConnected(device)
        #expect(await discovery.videoDevices.count == 1)
    }

    @Test("simulateVideoDeviceDisconnected removes from list")
    func simulateVideoDisconnected() async {
        let discovery = DeviceDiscovery()
        let device = VideoDeviceInfo(
            id: "cam-1", name: "Test Cam",
            connectionType: .usb)
        await discovery.simulateVideoDeviceConnected(device)
        await discovery.simulateVideoDeviceDisconnected(
            videoDeviceID: "cam-1")
        #expect(await discovery.videoDevices.isEmpty)
    }

    @Test("defaultAudioDevice returns default device")
    func defaultAudioDevice() async {
        let discovery = DeviceDiscovery()
        let device = AudioDeviceInfo(
            id: "mic-1", name: "Default Mic",
            connectionType: .builtIn, inputChannelCount: 1,
            supportedSampleRates: [.rate44100], isDefault: true)
        await discovery.simulateDeviceConnected(device)
        let defaultDevice = await discovery.defaultAudioDevice
        #expect(defaultDevice?.id == "mic-1")
    }

    @Test("defaultAudioDevice returns first when no default")
    func defaultAudioDeviceFirst() async {
        let discovery = DeviceDiscovery()
        let device = AudioDeviceInfo(
            id: "mic-1", name: "Non-default Mic",
            connectionType: .usb, inputChannelCount: 1,
            supportedSampleRates: [.rate44100], isDefault: false)
        await discovery.simulateDeviceConnected(device)
        let defaultDevice = await discovery.defaultAudioDevice
        #expect(defaultDevice?.id == "mic-1")
    }

    @Test("defaultVideoDevice returns first device")
    func defaultVideoDevice() async {
        let discovery = DeviceDiscovery()
        let device = VideoDeviceInfo(
            id: "cam-1", name: "Test Cam",
            connectionType: .builtIn)
        await discovery.simulateVideoDeviceConnected(device)
        let defaultDevice = await discovery.defaultVideoDevice
        #expect(defaultDevice?.id == "cam-1")
    }

    @Test("deviceChanges stream exists")
    func deviceChangesStream() async {
        let discovery = DeviceDiscovery()
        _ = await discovery.deviceChanges
    }
}
