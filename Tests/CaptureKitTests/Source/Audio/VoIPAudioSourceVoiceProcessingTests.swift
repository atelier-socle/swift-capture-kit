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

    @Test("VP failure falls back and still delivers buffers")
    func vpFailureFallsBackAndDeliversBuffers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let engine = MockAudioCaptureEngine()
        let format = AudioFormat(
            sampleRate: .rate48000, channelCount: 1,
            channelLayout: .mono, bitDepth: .float32
        )
        let samples: [CapturedAudioSample] = (0..<5).map {
            CapturedAudioSample(
                data: Data(repeating: UInt8($0), count: 960),
                timestamp: Double($0) * 0.02,
                format: format
            )
        }
        await engine.setSyntheticSamples(samples)
        await engine.setVoiceProcessingShouldFail(true)

        let source = VoIPAudioSource(
            voiceProcessingEnabled: true, captureEngine: engine
        )
        let stream = try await source.startCapture()

        var bufferCount = 0
        for await _ in stream {
            bufferCount += 1
        }

        #expect(bufferCount > 0, "VP fallback should deliver audio buffers")
        let startCount = await engine.startCallCount
        #expect(startCount == 2, "Should restart capture after VP failure")
        let vpEnabled = await engine.voiceProcessingEnabled
        #expect(vpEnabled == false, "VP should remain disabled after fallback")
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
