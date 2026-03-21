// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("VoIPAudioSource", .timeLimit(.minutes(1)))
struct VoIPAudioSourceTests {

    @Test("has voip source type")
    func sourceType() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = VoIPAudioSource()
        let type = await source.sourceType
        #expect(type == .voip)
    }

    @Test("voiceProcessingEnabled defaults to true")
    func voiceProcessingEnabledDefaultsToTrue() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = VoIPAudioSource()
        let enabled = await source.voiceProcessingEnabled
        #expect(enabled == true)
    }

    @Test("voiceIsolationEnabled defaults to false")
    func voiceIsolationEnabledDefaultsToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = VoIPAudioSource()
        let enabled = await source.voiceIsolationEnabled
        #expect(enabled == false)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = VoIPAudioSource()
        try await source.configure(.voiceChat)
        let format = await source.activeFormat
        #expect(format != nil)
        #expect(format?.sampleRate == .rate16000)
        #expect(format?.channelCount == 1)
    }

    @Test("default configuration is voiceChat")
    func defaultConfigurationIsVoiceChat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = VoIPAudioSource()
        let formats = await source.supportedFormats
        #expect(formats.count == 1)
        let format = formats[0]
        #expect(format.sampleRate == .rate16000)
        #expect(format.channelCount == 1)
    }

    @Test("availability requires microphone permission")
    func availabilityRequiresMicrophonePermission() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = VoIPAudioSource()
        let availability = source.availability
        #expect(availability.requiredPermissions.contains(.microphone))
    }

    @Test("is not capturing initially")
    func notCapturingInitially() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = VoIPAudioSource()
        let capturing = await source.isCapturing
        #expect(capturing == false)
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = VoIPAudioSource(
            voiceProcessingEnabled: true,
            captureEngine: MockAudioCaptureEngine()
        )
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)

        await source.stopCapture()
        let stopped = await source.isCapturing
        #expect(stopped == false)
    }
}
