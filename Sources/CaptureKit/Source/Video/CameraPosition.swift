// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Camera position relative to the device.
public enum CameraPosition: String, Sendable, CaseIterable {
    /// User-facing camera (selfie).
    case front

    /// World-facing camera (main).
    case back

    /// Position is not specified or unknown.
    case unspecified
}
