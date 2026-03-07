// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Opus application mode (affects encoder tuning).
public enum OpusApplication: String, Sendable, CaseIterable {
    /// Optimized for generic audio (music, mixed content).
    case audio
    /// Optimized for voice (VoIP, conferencing).
    case voip
    /// Restricted low delay — minimal algorithmic delay.
    case restrictedLowDelay
}

/// Configuration for the Opus encoder (via AudioToolbox, macOS 14+ / iOS 17+).
public struct OpusEncoderConfiguration: Sendable, Equatable {
    /// Target bitrate in bits per second (6,000–510,000).
    public var bitrate: Int
    /// Bitrate mode.
    public var bitrateMode: AudioBitrateMode
    /// Output sample rate (Opus supports 8, 12, 16, 24, 48 kHz).
    public var sampleRate: SampleRate
    /// Number of output channels (1–8).
    public var channelCount: Int
    /// Opus application mode.
    public var application: OpusApplication

    /// Creates a new Opus encoder configuration.
    public init(
        bitrate: Int = 128_000,
        bitrateMode: AudioBitrateMode = .variable,
        sampleRate: SampleRate = .rate48000,
        channelCount: Int = 2,
        application: OpusApplication = .audio
    ) {
        self.bitrate = bitrate
        self.bitrateMode = bitrateMode
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.application = application
    }

    /// Validate the configuration.
    public func validate() throws {
        guard (6_000...510_000).contains(bitrate) else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "opus",
                reason: "Bitrate \(bitrate) is outside the valid range 6000...510000"
            )
        }
        guard channelCount >= 1 && channelCount <= 8 else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "opus",
                reason: "Channel count must be between 1 and 8"
            )
        }
    }

    /// Voice chat — 32 kbps mono, low latency.
    public static let voiceChat = OpusEncoderConfiguration(
        bitrate: 32_000, bitrateMode: .variable,
        sampleRate: .rate48000, channelCount: 1, application: .voip
    )

    /// Music streaming — 128 kbps stereo.
    public static let musicStreaming = OpusEncoderConfiguration(
        bitrate: 128_000, bitrateMode: .variable,
        sampleRate: .rate48000, channelCount: 2, application: .audio
    )

    /// Low latency — 64 kbps stereo, restricted bandwidth.
    public static let lowLatency = OpusEncoderConfiguration(
        bitrate: 64_000, bitrateMode: .constrained,
        sampleRate: .rate48000, channelCount: 2,
        application: .restrictedLowDelay
    )
}
