// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Torch (flashlight) mode for video capture.
public enum TorchMode: String, Sendable, CaseIterable {
    /// Torch is off.
    case off

    /// Torch is always on during capture.
    case on

    /// Torch activates automatically in low-light conditions.
    case auto
}
