// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// AV1 encoding profile.
public enum AV1Profile: String, Sendable, CaseIterable {
    /// Main — 8/10-bit 4:2:0. Standard content.
    case main
    /// High — 8/10-bit 4:4:4. Professional content.
    case high
}
