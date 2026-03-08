// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

/// Mock audio capture engine for testing without hardware.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockAudioCaptureEngine: AudioCaptureProviding {
    private var _isCapturing = false
    var isCapturing: Bool { _isCapturing }

    /// Synthetic samples to emit when capture starts.
    var syntheticSamples: [CapturedAudioSample] = []

    /// Number of startCapture calls.
    var startCallCount = 0

    /// Number of stopCapture calls.
    var stopCallCount = 0

    /// The last device ID passed to startCapture.
    var lastDeviceID: String?

    /// The last configuration passed to startCapture.
    var lastConfiguration: AudioSourceConfiguration?

    /// The last audio session category.
    var lastSessionCategory: String?

    /// The last audio session mode.
    var lastSessionMode: String?

    /// The last input gain value set.
    var lastInputGain: Float?

    /// Whether voice processing was enabled.
    var voiceProcessingEnabled: Bool = false

    func startCapture(
        configuration: AudioSourceConfiguration,
        deviceID: String?
    ) async throws -> AsyncStream<CapturedAudioSample> {
        startCallCount += 1
        _isCapturing = true
        lastConfiguration = configuration
        lastDeviceID = deviceID

        let samples = syntheticSamples
        return AsyncStream { continuation in
            for sample in samples {
                continuation.yield(sample)
            }
            continuation.finish()
        }
    }

    func stopCapture() async {
        stopCallCount += 1
        _isCapturing = false
    }

    func inputFormat() async -> AudioFormat? {
        AudioFormat(
            sampleRate: .rate48000,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .float32
        )
    }

    func configureAudioSession(
        category: String, mode: String
    ) async throws {
        lastSessionCategory = category
        lastSessionMode = mode
    }

    func setInputGain(_ gain: Float) async throws {
        lastInputGain = gain
    }

    func setVoiceProcessingEnabled(_ enabled: Bool) async throws {
        voiceProcessingEnabled = enabled
    }
}
