// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Focus subject for cinematic camera mode.
public enum CinematicFocusSubject: Sendable, Equatable {
    /// AI automatically selects and tracks the primary subject.
    case automatic

    /// Focus on a specific detected person (nil = first detected).
    case person(identifier: Int?)

    /// Focus on a specific screen point (normalized 0.0–1.0).
    case point(x: Double, y: Double)

    /// Focus on a specific region of interest.
    case object(x: Double, y: Double, width: Double, height: Double)
}
