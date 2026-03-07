// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// HDR encoding mode for HEVC.
public enum HDRMode: String, Sendable, CaseIterable {
    /// Standard dynamic range — no HDR metadata.
    case sdr
    /// HDR10 — static metadata, PQ transfer function, Rec.2020.
    case hdr10
    /// Hybrid Log-Gamma — broadcast HDR, backward compatible with SDR.
    case hlg
    /// Dolby Vision — dynamic metadata, profile 8.4.
    case dolbyVision

    /// The minimum HEVC profile required for this HDR mode.
    public var requiredProfile: HEVCProfile {
        switch self {
        case .sdr: return .main
        case .hdr10, .hlg, .dolbyVision: return .main10
        }
    }
}
