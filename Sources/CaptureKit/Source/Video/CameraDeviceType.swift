// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Type of camera hardware.
public enum CameraDeviceType: String, Sendable, CaseIterable {
    /// Standard wide-angle camera.
    case wideAngle

    /// Ultra-wide-angle camera (0.5x).
    case ultraWideAngle

    /// Telephoto camera (2x, 3x, 5x).
    case telephoto

    /// Dual camera system (wide + telephoto).
    case dualCamera

    /// Dual wide camera system (ultra-wide + wide).
    case dualWideCamera

    /// Triple camera system (ultra-wide + wide + telephoto).
    case tripleCamera

    /// LiDAR scanner (iPhone 12 Pro+).
    case lidarScanner

    /// TrueDepth front camera (Face ID).
    case trueDepth

    /// iPhone used as webcam via Continuity Camera.
    case continuityCamera

    /// External USB or Thunderbolt camera.
    case externalUnknown
}
