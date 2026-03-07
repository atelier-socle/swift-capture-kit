// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

extension CaptureQualityLevel {
    /// The next lower quality level (nil if already at minimum).
    public var degraded: CaptureQualityLevel? {
        switch self {
        case .maximum: return .high
        case .high: return .medium
        case .medium: return .low
        case .low: return .minimum
        case .minimum: return nil
        }
    }

    /// The next higher quality level (nil if already at maximum).
    public var improved: CaptureQualityLevel? {
        switch self {
        case .minimum: return .low
        case .low: return .medium
        case .medium: return .high
        case .high: return .maximum
        case .maximum: return nil
        }
    }
}
