// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("VoIPAudioSource Voice Processing")
struct VoIPAudioSourceVoiceProcessingTests {

    @Test("startCapture enables voice processing on engine")
    func startCaptureEnablesVoiceProcessing() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let engine = MockAudioCaptureEngine()
        let source = VoIPAudioSource(
            voiceProcessingEnabled: true, captureEngine: engine)
        _ = try await source.startCapture()
        let enabled = await engine.voiceProcessingEnabled
        #expect(enabled == true)
    }

    @Test("startCapture with voice processing disabled does not enable it")
    func startCaptureWithVoiceProcessingDisabled() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let engine = MockAudioCaptureEngine()
        let source = VoIPAudioSource(
            voiceProcessingEnabled: false, captureEngine: engine)
        _ = try await source.startCapture()
        let enabled = await engine.voiceProcessingEnabled
        #expect(enabled == false)
    }

    @Test("voiceIsolationEnabled can be set")
    func voiceIsolationEnabledCanBeSet() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = VoIPAudioSource(
            voiceProcessingEnabled: false, captureEngine: MockAudioCaptureEngine())
        await source.setVoiceIsolationForTesting(true)
        let enabled = await source.voiceIsolationEnabled
        #expect(enabled == true)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension VoIPAudioSource {
    func setVoiceIsolationForTesting(_ enabled: Bool) {
        self.voiceIsolationEnabled = enabled
    }
}
