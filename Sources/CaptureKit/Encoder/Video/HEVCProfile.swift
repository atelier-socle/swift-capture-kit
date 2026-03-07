// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// HEVC/H.265 encoding profile.
public enum HEVCProfile: String, Sendable, CaseIterable {
    /// Main — 8-bit 4:2:0. Standard SDR content.
    case main
    /// Main 10 — 10-bit 4:2:0. Required for HDR10, HLG, Dolby Vision.
    case main10
    /// Main 4:2:2 10-bit — professional. Higher chroma resolution.
    case main42210

    /// Bit depth for this profile.
    public var bitDepth: Int {
        switch self {
        case .main: return 8
        case .main10, .main42210: return 10
        }
    }

    /// Whether this profile supports HDR content.
    public var supportsHDR: Bool {
        self != .main
    }

    /// Chroma subsampling format.
    public var chromaSubsampling: String {
        switch self {
        case .main, .main10: return "4:2:0"
        case .main42210: return "4:2:2"
        }
    }
}
