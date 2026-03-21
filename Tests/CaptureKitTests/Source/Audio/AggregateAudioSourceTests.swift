// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

#if os(macOS)

    @Suite("AggregateAudioSource", .timeLimit(.minutes(1)))
    struct AggregateAudioSourceTests {

        private func makeTestDevice(id: String = "test-device") -> AudioDeviceInfo {
            AudioDeviceInfo(
                id: id,
                name: "Test Device",
                connectionType: .usb,
                inputChannelCount: 2,
                supportedSampleRates: [.rate44100, .rate48000]
            )
        }

        @Test("has aggregate source type")
        func sourceType() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = AggregateAudioSource(devices: [])
            let type = await source.sourceType
            #expect(type == .aggregate)
        }

        @Test("is not capturing initially")
        func notCapturingInitially() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = AggregateAudioSource(devices: [])
            let capturing = await source.isCapturing
            #expect(capturing == false)
        }

        @Test("driftCompensation defaults to true")
        func driftCompensationDefaultsToTrue() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = AggregateAudioSource(devices: [])
            let drift = await source.driftCompensation
            #expect(drift == true)
        }

        @Test("configure validates minimum two devices")
        func configureValidatesMinimumTwoDevices() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = AggregateAudioSource(devices: [makeTestDevice(id: "device-1")])

            await #expect(throws: CaptureError.self) {
                try await source.configure(.default)
            }
        }

        @Test("configure succeeds with two or more devices")
        func configureSucceedsWithTwoOrMoreDevices() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = AggregateAudioSource(devices: [
                makeTestDevice(id: "device-1"),
                makeTestDevice(id: "device-2")
            ])

            try await source.configure(.default)
            let format = await source.activeFormat
            #expect(format != nil)
            #expect(format?.sampleRate == .rate48000)
        }

        @Test("availability requires microphone permission")
        func availabilityRequiresMicrophonePermission() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = AggregateAudioSource(devices: [])
            let availability = source.availability
            #expect(availability.requiredPermissions.contains(.microphone))
        }

        @Test("availability notes mention macOS")
        func availabilityNotesMentionMacOS() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = AggregateAudioSource(devices: [])
            let availability = source.availability
            #expect(availability.notes != nil)
            #expect(availability.notes?.contains("macOS") == true)
        }

        @Test("stopCapture sets isCapturing to false")
        func stopCaptureSetsIsCapturingToFalse() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = AggregateAudioSource(devices: [
                makeTestDevice(id: "device-1"),
                makeTestDevice(id: "device-2")
            ])
            _ = try await source.startCapture()
            let capturing = await source.isCapturing
            #expect(capturing == true)

            await source.stopCapture()
            let stopped = await source.isCapturing
            #expect(stopped == false)
        }
    }

#endif
