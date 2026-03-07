// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// H.264/AVC encoding profile.
public enum H264Profile: String, Sendable, CaseIterable {
    /// Baseline — widest compatibility, no B-frames, CAVLC only.
    case baseline
    /// Main — B-frames, CABAC. Good balance of quality and compatibility.
    case main
    /// High — 8x8 transform, quantization scaling. Best quality at given bitrate.
    case high
    /// High 10 — 10-bit depth. Limited hardware encoder support.
    case high10

    /// Whether this profile supports B-frames.
    public var supportsBFrames: Bool {
        self != .baseline
    }

    /// Whether this profile supports CABAC entropy coding.
    public var supportsCabac: Bool {
        self != .baseline
    }

    /// Maximum supported bit depth.
    public var maxBitDepth: Int {
        switch self {
        case .high10: return 10
        default: return 8
        }
    }
}
