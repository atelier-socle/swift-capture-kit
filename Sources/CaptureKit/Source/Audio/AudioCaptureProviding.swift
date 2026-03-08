// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Internal protocol abstracting audio capture engine (AVAudioEngine).
///
/// Enables dependency injection for testing: real implementation uses
/// AVAudioEngine, tests inject a mock that produces synthetic buffers.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
protocol AudioCaptureProviding: Sendable {
    /// Start capturing audio with the given configuration.
    ///
    /// - Parameters:
    ///   - configuration: The audio source configuration.
    ///   - deviceID: Optional device identifier for input selection.
    /// - Returns: An AsyncStream of captured audio samples.
    func startCapture(
        configuration: AudioSourceConfiguration,
        deviceID: String?
    ) async throws -> AsyncStream<CapturedAudioSample>

    /// Stop capturing.
    func stopCapture() async

    /// Whether capture is currently active.
    var isCapturing: Bool { get async }

    /// Query the hardware input format.
    func inputFormat() async -> AudioFormat?

    /// Configure audio session (iOS/visionOS only).
    func configureAudioSession(
        category: String, mode: String
    ) async throws

    /// Set the input gain level (0.0 to 1.0).
    ///
    /// On macOS, sets AVAudioEngine inputNode volume.
    /// On iOS/visionOS, sets AVAudioSession inputGain.
    func setInputGain(_ gain: Float) async throws

    /// Enable or disable voice processing on the input node.
    ///
    /// When enabled, the system applies echo cancellation and noise suppression
    /// optimized for voice communication.
    func setVoiceProcessingEnabled(_ enabled: Bool) async throws
}

/// A raw audio sample from the capture engine.
struct CapturedAudioSample: Sendable {
    /// The raw audio data.
    let data: Data
    /// The presentation timestamp in seconds.
    let timestamp: TimeInterval
    /// The audio format of this sample.
    let format: AudioFormat
}
