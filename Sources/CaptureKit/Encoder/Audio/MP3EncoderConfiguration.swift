// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the MP3 encoder (macOS only).
public struct MP3EncoderConfiguration: Sendable, Equatable {
    /// Target bitrate in bits per second (32,000–320,000).
    public var bitrate: Int
    /// Bitrate mode.
    public var bitrateMode: AudioBitrateMode
    /// Output sample rate (MP3 supports 8–48 kHz).
    public var sampleRate: SampleRate
    /// Number of output channels (mono or stereo).
    public var channelCount: Int
    /// MP3 quality (0 = best, 9 = fastest).
    public var quality: Int

    /// Creates a new MP3 encoder configuration.
    public init(
        bitrate: Int = 192_000,
        bitrateMode: AudioBitrateMode = .constant,
        sampleRate: SampleRate = .rate44100,
        channelCount: Int = 2,
        quality: Int = 2
    ) {
        self.bitrate = bitrate
        self.bitrateMode = bitrateMode
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.quality = quality
    }

    /// Validate quality is 0–9, channelCount <= 2.
    public func validate() throws {
        guard (0...9).contains(quality) else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "mp3",
                reason: "Quality \(quality) is outside the valid range 0...9"
            )
        }
        guard channelCount >= 1 && channelCount <= 2 else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "mp3",
                reason: "MP3 supports at most 2 channels"
            )
        }
    }

    /// Standard — 192 kbps CBR stereo.
    public static let standard = MP3EncoderConfiguration(
        bitrate: 192_000, bitrateMode: .constant,
        sampleRate: .rate44100, channelCount: 2
    )

    /// High quality — 320 kbps CBR stereo.
    public static let highQuality = MP3EncoderConfiguration(
        bitrate: 320_000, bitrateMode: .constant,
        sampleRate: .rate44100, channelCount: 2
    )

    /// Web radio — 128 kbps CBR stereo (Icecast compatible).
    public static let webRadio = MP3EncoderConfiguration(
        bitrate: 128_000, bitrateMode: .constant,
        sampleRate: .rate44100, channelCount: 2
    )
}
