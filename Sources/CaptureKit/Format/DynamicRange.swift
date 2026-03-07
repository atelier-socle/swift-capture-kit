// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Describes the dynamic range capability of video content.
public enum DynamicRange: String, Sendable, CaseIterable {
    /// Standard Dynamic Range.
    case sdr

    /// HDR10 — static metadata, PQ transfer.
    case hdr10

    /// HDR10+ — dynamic metadata, PQ transfer.
    case hdr10Plus

    /// Dolby Vision — proprietary dynamic HDR.
    case dolbyVision

    /// Hybrid Log-Gamma — broadcast-compatible HDR.
    case hlg
}
