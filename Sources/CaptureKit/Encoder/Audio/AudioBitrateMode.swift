// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Bitrate mode for audio encoding.
public enum AudioBitrateMode: String, Sendable, CaseIterable {
    /// Constant bitrate — consistent output rate.
    case constant
    /// Variable bitrate — quality-based, varying output rate.
    case variable
    /// Constrained variable bitrate — VBR with maximum bitrate cap.
    case constrained
}
