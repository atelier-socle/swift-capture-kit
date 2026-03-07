// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Named presets for audio encoding, combining codec + configuration.
public enum AudioEncoderPreset: String, Sendable, CaseIterable {
    // MARK: - Podcast

    /// AAC-LC 128 kbps stereo 48 kHz.
    case podcastStandard
    /// AAC-LC 256 kbps stereo 48 kHz.
    case podcastHQ
    /// FLAC lossless stereo 48 kHz.
    case podcastLossless

    // MARK: - Music

    /// AAC-LC 256 kbps VBR stereo 48 kHz.
    case musicAAC
    /// ALAC lossless stereo 48 kHz 24-bit.
    case musicLossless

    // MARK: - Voice

    /// Opus 32 kbps mono — VoIP optimized.
    case voiceOpus
    /// AAC-ELD 32 kbps mono — ultra-low latency.
    case voiceLowLatency
    /// HE-AAC v2 24 kbps stereo — minimal bandwidth.
    case voiceMinimalBandwidth

    // MARK: - Streaming

    /// AAC-LC 128 kbps stereo — Twitch/YouTube standard.
    case streamingStandard
    /// AAC-LC 320 kbps stereo — high quality streaming.
    case streamingHQ
    /// Opus 128 kbps stereo — web streaming.
    case streamingOpus

    // MARK: - Web Radio

    /// MP3 128 kbps stereo — Icecast compatible (macOS only).
    case webRadioMP3128
    /// MP3 320 kbps stereo (macOS only).
    case webRadioMP3320
    /// AAC-LC 96 kbps stereo.
    case webRadioAAC96

    // MARK: - Broadcast

    /// PCM 48 kHz 24-bit stereo — uncompressed broadcast.
    case broadcastPCM
    /// FLAC 48 kHz 24-bit stereo — lossless broadcast.
    case broadcastFLAC

    /// The audio codec used by this preset.
    public var codec: AudioCodec {
        switch self {
        case .podcastStandard, .podcastHQ, .musicAAC,
            .voiceLowLatency, .voiceMinimalBandwidth,
            .streamingStandard, .streamingHQ, .webRadioAAC96:
            return .aac
        case .musicLossless:
            return .alac
        case .voiceOpus, .streamingOpus:
            return .opus
        case .podcastLossless, .broadcastFLAC:
            return .flac
        case .broadcastPCM:
            return .pcm
        case .webRadioMP3128, .webRadioMP3320:
            return .mp3
        }
    }

    /// Whether this preset requires macOS (MP3 presets).
    public var isMacOSOnly: Bool {
        switch self {
        case .webRadioMP3128, .webRadioMP3320:
            return true
        default:
            return false
        }
    }
}
