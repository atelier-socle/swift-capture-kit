// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Spatial video capture mode for visionOS.
public enum SpatialCaptureMode: String, Sendable, CaseIterable {
    /// Stereoscopic left/right eye pair encoded as MV-HEVC.
    case stereoscopic

    /// Single view fallback for non-spatial displays.
    case monoFallback
}
