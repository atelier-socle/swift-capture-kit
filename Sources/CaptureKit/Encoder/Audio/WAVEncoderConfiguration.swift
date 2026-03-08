// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the WAV encoder.
public struct WAVEncoderConfiguration: Sendable, Equatable {
    /// Sample rate.
    public var sampleRate: SampleRate
    /// Number of channels.
    public var channelCount: Int
    /// Bit depth (determines bytes per sample in the WAV header).
    public var bitDepth: AudioBitDepth

    /// Creates a new WAV encoder configuration.
    ///
    /// - Parameters:
    ///   - sampleRate: Output sample rate. Defaults to 48 kHz.
    ///   - channelCount: Number of channels. Defaults to 2 (stereo).
    ///   - bitDepth: Audio bit depth. Defaults to 16-bit integer.
    public init(
        sampleRate: SampleRate = .rate48000,
        channelCount: Int = 2,
        bitDepth: AudioBitDepth = .int16
    ) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.bitDepth = bitDepth
    }

    /// CD quality — 44.1 kHz, stereo, 16-bit.
    public static let cdQuality = WAVEncoderConfiguration(
        sampleRate: .rate44100, channelCount: 2, bitDepth: .int16
    )

    /// Broadcast — 48 kHz, stereo, 24-bit.
    public static let broadcast = WAVEncoderConfiguration(
        sampleRate: .rate48000, channelCount: 2, bitDepth: .int24
    )

    /// Voice — 16 kHz, mono, 16-bit.
    public static let voice = WAVEncoderConfiguration(
        sampleRate: .rate16000, channelCount: 1, bitDepth: .int16
    )
}
