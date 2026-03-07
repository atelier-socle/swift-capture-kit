// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// AAC encoder profile.
public enum AACProfile: String, Sendable, CaseIterable {
    /// AAC Low Complexity — general purpose, widest compatibility.
    case lc
    /// High-Efficiency AAC v1 (SBR) — optimized for low bitrate.
    case heV1
    /// High-Efficiency AAC v2 (SBR+PS) — very low bitrate, stereo only.
    case heV2
    /// AAC Enhanced Low Delay — ultra-low latency for VoIP/talkback.
    case eld
    /// Extended High-Efficiency AAC — adaptive bitrate, voice+music.
    case xHE

    /// Valid bitrate range for the profile.
    public var bitrateRange: ClosedRange<Int> {
        switch self {
        case .lc: return 32_000...320_000
        case .heV1: return 16_000...128_000
        case .heV2: return 12_000...64_000
        case .eld: return 16_000...128_000
        case .xHE: return 8_000...256_000
        }
    }

    /// Maximum supported channel count.
    public var maxChannels: Int {
        switch self {
        case .lc, .xHE: return 8
        case .heV1: return 8
        case .heV2: return 2
        case .eld: return 2
        }
    }

    /// Whether the profile is designed for low-latency use.
    public var supportsLowLatency: Bool {
        switch self {
        case .eld: return true
        default: return false
        }
    }
}
