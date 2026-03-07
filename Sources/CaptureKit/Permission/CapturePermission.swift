// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Simplified permission type for SwiftUI helpers.
///
/// Maps to PermissionType but with a reduced set relevant for capture UX.
public enum CapturePermission: String, Sendable, CaseIterable {
    /// Microphone access for audio capture.
    case microphone
    /// Camera access for video capture.
    case camera
    /// Screen recording access (macOS only — requires TCC).
    case screenCapture

    /// The corresponding full permission type.
    public var permissionType: PermissionType {
        switch self {
        case .microphone: .microphone
        case .camera: .camera
        case .screenCapture: .screenRecording
        }
    }
}
