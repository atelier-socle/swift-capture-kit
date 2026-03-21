// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("LineInSource", .timeLimit(.minutes(1)))
struct LineInSourceTests {

    private func makeTestDevice(id: String = "test-device") -> AudioDeviceInfo {
        AudioDeviceInfo(
            id: id,
            name: "Test Device",
            connectionType: .usb,
            inputChannelCount: 2,
            supportedSampleRates: [.rate44100, .rate48000]
        )
    }

    @Test("has lineIn source type")
    func sourceType() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(device: makeTestDevice())
        let type = await source.sourceType
        #expect(type == .lineIn)
    }

    @Test("is not capturing initially")
    func notCapturingInitially() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(device: makeTestDevice())
        let capturing = await source.isCapturing
        #expect(capturing == false)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(device: makeTestDevice())
        try await source.configure(.default)
        let format = await source.activeFormat
        #expect(format != nil)
        #expect(format?.sampleRate == .rate48000)
        #expect(format?.channelCount == 2)
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(device: makeTestDevice())
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
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(device: makeTestDevice())
        _ = try await source.startCapture()

        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
        await source.stopCapture()
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(device: makeTestDevice())
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)

        await source.stopCapture()
        let stopped = await source.isCapturing
        #expect(stopped == false)
    }

    @Test("inputGain defaults to 1.0")
    func inputGainDefaultsToOne() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(device: makeTestDevice())
        let gain = await source.inputGain
        #expect(gain == 1.0)
    }

    @Test("inputGain is clamped to 0.0 to 1.0 range")
    func inputGainIsClamped() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let sourceHigh = LineInSource(device: makeTestDevice(), inputGain: 2.5)
        let gainHigh = await sourceHigh.inputGain
        #expect(gainHigh == 1.0)

        let sourceLow = LineInSource(device: makeTestDevice(), inputGain: -0.5)
        let gainLow = await sourceLow.inputGain
        #expect(gainLow == 0.0)
    }

    @Test("availability requires microphone permission")
    func availabilityRequiresMicrophonePermission() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(device: makeTestDevice())
        let availability = source.availability
        #expect(availability.requiredPermissions.contains(.microphone))
    }

    @Test("channel mapping defaults to nil")
    func channelMappingDefaultsToNil() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(device: makeTestDevice())
        let mapping = await source.channelMapping
        #expect(mapping == nil)
    }
}
