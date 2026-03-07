// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Standard broadcast test patterns.
public enum TestPattern: String, Sendable, CaseIterable {
    /// SMPTE color bars (SMPTE RP 219, broadcast standard).
    case smpteBars

    /// SMPTE HD color bars (1080p variant).
    case smpteHD

    /// EBU 100% color bars (full amplitude).
    case ebu100

    /// EBU 75% color bars (75% amplitude).
    case ebu75

    /// Alignment grid overlay.
    case grid

    /// Checkerboard pattern.
    case checkerboard

    /// Gray ramp (for gamma calibration).
    case grayRamp

    /// X-Rite ColorChecker chart.
    case colorChecker

    /// Zone plate (for resolution testing).
    case zoneplate

    /// Countdown leader.
    case countdown
}
