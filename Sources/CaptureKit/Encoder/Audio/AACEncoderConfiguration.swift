// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the AAC encoder.
public struct AACEncoderConfiguration: Sendable, Equatable {
    /// AAC profile to use.
    public var profile: AACProfile
    /// Target bitrate in bits per second.
    public var bitrate: Int
    /// Bitrate mode (CBR, VBR, CVBR).
    public var bitrateMode: AudioBitrateMode
    /// Output sample rate.
    public var sampleRate: SampleRate
    /// Number of output channels.
    public var channelCount: Int

    /// Creates a new AAC encoder configuration.
    public init(
        profile: AACProfile = .lc,
        bitrate: Int = 128_000,
        bitrateMode: AudioBitrateMode = .constant,
        sampleRate: SampleRate = .rate48000,
        channelCount: Int = 2
    ) {
        self.profile = profile
        self.bitrate = bitrate
        self.bitrateMode = bitrateMode
        self.sampleRate = sampleRate
        self.channelCount = channelCount
    }

    /// Validate the configuration against profile constraints.
    public func validate() throws {
        guard channelCount >= 1 else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "aac",
                reason: "Channel count must be at least 1"
            )
        }
        if profile == .heV2 && channelCount != 2 {
            throw CaptureError.encoderConfigurationFailed(
                codec: "aac",
                reason: "HE-AAC v2 requires exactly 2 channels"
            )
        }
        if profile == .eld && channelCount > 2 {
            throw CaptureError.encoderConfigurationFailed(
                codec: "aac",
                reason: "AAC-ELD supports at most 2 channels"
            )
        }
        guard profile.bitrateRange.contains(bitrate) else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "aac",
                reason: "Bitrate \(bitrate) is outside the valid range \(profile.bitrateRange) for profile \(profile.rawValue)"
            )
        }
    }

    /// Voice — AAC-LC mono 64 kbps 48 kHz.
    public static let voice = AACEncoderConfiguration(
        profile: .lc, bitrate: 64_000, bitrateMode: .constant,
        sampleRate: .rate48000, channelCount: 1
    )

    /// Podcast — AAC-LC stereo 128 kbps 48 kHz.
    public static let podcast = AACEncoderConfiguration(
        profile: .lc, bitrate: 128_000, bitrateMode: .constant,
        sampleRate: .rate48000, channelCount: 2
    )

    /// Music high quality — AAC-LC stereo 256 kbps 48 kHz.
    public static let musicHQ = AACEncoderConfiguration(
        profile: .lc, bitrate: 256_000, bitrateMode: .variable,
        sampleRate: .rate48000, channelCount: 2
    )

    /// Streaming low bandwidth — HE-AAC v1 stereo 64 kbps.
    public static let streamingLowBandwidth = AACEncoderConfiguration(
        profile: .heV1, bitrate: 64_000, bitrateMode: .constant,
        sampleRate: .rate44100, channelCount: 2
    )

    /// Ultra-low latency — AAC-ELD mono 32 kbps (VoIP).
    public static let lowLatency = AACEncoderConfiguration(
        profile: .eld, bitrate: 32_000, bitrateMode: .constant,
        sampleRate: .rate16000, channelCount: 1
    )
}
