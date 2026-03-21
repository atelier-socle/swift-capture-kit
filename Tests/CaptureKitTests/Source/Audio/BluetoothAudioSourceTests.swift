// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("BluetoothAudioSource", .timeLimit(.minutes(1)))
struct BluetoothAudioSourceTests {

    private func makeTestDevice(id: String = "test-device") -> AudioDeviceInfo {
        AudioDeviceInfo(
            id: id,
            name: "Test Device",
            connectionType: .usb,
            inputChannelCount: 2,
            supportedSampleRates: [.rate44100, .rate48000]
        )
    }

    @Test("has bluetooth source type")
    func sourceType() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(device: makeTestDevice())
        let type = await source.sourceType
        #expect(type == .bluetooth)
    }

    @Test("is not capturing initially")
    func notCapturingInitially() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(device: makeTestDevice())
        let capturing = await source.isCapturing
        #expect(capturing == false)
    }

    @Test("preferredCodec defaults to nil")
    func preferredCodecDefaultsToNil() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(device: makeTestDevice())
        let codec = await source.preferredCodec
        #expect(codec == nil)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(device: makeTestDevice())
        try await source.configure(.default)
        let format = await source.activeFormat
        #expect(format != nil)
        #expect(format?.sampleRate == .rate48000)
        #expect(format?.channelCount == 2)
    }

    @Test("availability requires bluetooth and microphone permissions")
    func availabilityRequiresBluetoothAndMicrophonePermissions() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(device: makeTestDevice())
        let availability = source.availability
        #expect(availability.requiredPermissions.contains(.bluetooth))
        #expect(availability.requiredPermissions.contains(.microphone))
    }

    @Test("startCapture while capturing throws")
    func startCaptureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(device: makeTestDevice())
        _ = try await source.startCapture()

        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
        await source.stopCapture()
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(device: makeTestDevice())
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)

        await source.stopCapture()
        let stopped = await source.isCapturing
        #expect(stopped == false)
    }

    @Test("selected device is stored")
    func selectedDeviceIsStored() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let device = makeTestDevice(id: "bt-headset")
        let source = BluetoothAudioSource(device: device)
        let selected = await source.selectedDevice
        #expect(selected.id == "bt-headset")
    }
}
