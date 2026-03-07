// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Status of a capture permission.
public enum PermissionStatus: String, Sendable, CaseIterable {
    /// User has not been asked yet.
    case notDetermined
    /// Permission granted.
    case authorized
    /// Permission explicitly denied by user.
    case denied
    /// Permission restricted by system policy (parental controls, MDM).
    case restricted
    /// Provisional permission (limited access).
    case provisional
}
