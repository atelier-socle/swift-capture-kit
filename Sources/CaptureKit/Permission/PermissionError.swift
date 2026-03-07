// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Errors specific to permission operations.
public enum PermissionError: Error, Sendable, CustomStringConvertible {
    /// Permission was denied by the user.
    case denied(PermissionType)
    /// Permission is restricted by system policy.
    case restricted(PermissionType)
    /// Permission type is not available on this platform.
    case notAvailableOnPlatform(PermissionType, platform: String)
    /// Failed to request permission.
    case requestFailed(PermissionType, reason: String)

    /// A human-readable description of the error.
    public var description: String {
        switch self {
        case .denied(let type):
            return "Permission denied: \(type.rawValue)"
        case .restricted(let type):
            return "Permission restricted: \(type.rawValue)"
        case .notAvailableOnPlatform(let type, let platform):
            return "\(type.rawValue) not available on \(platform)"
        case .requestFailed(let type, let reason):
            return "Permission request failed for \(type.rawValue): \(reason)"
        }
    }
}
