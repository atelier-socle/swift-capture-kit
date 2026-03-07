// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Represents the number of bits used per video sample component.
public enum BitDepth: Int, Sendable, CaseIterable, Comparable {
    /// 8 bits per component.
    case bit8 = 8

    /// 10 bits per component.
    case bit10 = 10

    /// 12 bits per component.
    case bit12 = 12

    /// 16 bits per component.
    case bit16 = 16

    /// Compares two bit depths by their underlying integer value.
    public static func < (lhs: BitDepth, rhs: BitDepth) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Represents the bit depth and numeric format of audio samples.
public enum AudioBitDepth: String, Sendable, CaseIterable {
    /// 16-bit signed integer PCM.
    case int16

    /// 24-bit signed integer PCM.
    case int24

    /// 32-bit signed integer PCM.
    case int32

    /// 32-bit IEEE 754 floating-point.
    case float32

    /// 64-bit IEEE 754 floating-point.
    case float64
}
