// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("MicrophoneSource", .timeLimit(.minutes(1)))
struct MicrophoneSourceTests {

    private func makeTestDevice(id: String = "test-device") -> AudioDeviceInfo {
        AudioDeviceInfo(
            id: id,
            name: "Test Device",
            connectionType: .usb,
            inputChannelCount: 2,
            supportedSampleRates: [.rate44100, .rate48000]
        )
    }

    @Test("has microphone source type")
    func sourceType() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        let type = await source.sourceType
        #expect(type == .microphone)
    }

    @Test("is not capturing initially")
    func notCapturingInitially() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        let capturing = await source.isCapturing
        #expect(capturing == false)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        try await source.configure(.default)
        let format = await source.activeFormat
        #expect(format != nil)
        #expect(format?.sampleRate == .rate48000)
        #expect(format?.channelCount == 2)
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)

        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
        await source.stopCapture()
    }

    @Test("startCapture while capturing throws")
    func startCaptureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        _ = try await source.startCapture()

        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
        await source.stopCapture()
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)

        await source.stopCapture()
        let stopped = await source.isCapturing
        #expect(stopped == false)
    }

    @Test("availability requires microphone permission")
    func availabilityRequiresMicrophonePermission() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        let availability = source.availability
        #expect(availability.requiredPermissions.contains(.microphone))
    }

    @Test("automaticGainControl defaults to true")
    func automaticGainControlDefaultsToTrue() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        let agc = await source.automaticGainControl
        #expect(agc == true)
    }

    @Test("echoCancellation defaults to false")
    func echoCancellationDefaultsToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        let ec = await source.echoCancellation
        #expect(ec == false)
    }

    @Test("voiceIsolation defaults to false")
    func voiceIsolationDefaultsToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MicrophoneSource()
        let vi = await source.voiceIsolation
        #expect(vi == false)
    }
}
