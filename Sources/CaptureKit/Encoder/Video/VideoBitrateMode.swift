// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Bitrate control mode for video encoding.
public enum VideoBitrateMode: String, Sendable, CaseIterable {
    /// Constant bitrate — consistent output rate, predictable bandwidth.
    case constant
    /// Average bitrate — targets average over a time window.
    case average
    /// Variable bitrate — quality-based, efficient but unpredictable.
    case variable
    /// Capped variable — VBR with a maximum bitrate ceiling.
    case capped
}
