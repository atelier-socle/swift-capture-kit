// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the Apple Lossless (ALAC) encoder.
public struct ALACEncoderConfiguration: Sendable, Equatable {
    /// Output sample rate.
    public var sampleRate: SampleRate
    /// Number of output channels.
    public var channelCount: Int
    /// Bit depth for encoding (16, 24, or 32-bit).
    public var bitDepth: AudioBitDepth

    /// Creates a new ALAC encoder configuration.
    public init(
        sampleRate: SampleRate = .rate48000,
        channelCount: Int = 2,
        bitDepth: AudioBitDepth = .int24
    ) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.bitDepth = bitDepth
    }

    /// CD quality — 44.1 kHz stereo 16-bit.
    public static let cdQuality = ALACEncoderConfiguration(
        sampleRate: .rate44100, channelCount: 2, bitDepth: .int16
    )

    /// Studio quality — 96 kHz stereo 24-bit.
    public static let studioQuality = ALACEncoderConfiguration(
        sampleRate: .rate96000, channelCount: 2, bitDepth: .int24
    )
}
