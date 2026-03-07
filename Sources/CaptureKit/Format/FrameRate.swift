// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Represents common video frame rates, including NTSC fractional rates
/// and an arbitrary custom rate.
public enum FrameRate: Sendable, Equatable, Hashable {
    /// 1 frame per second.
    case fps1

    /// 15 frames per second.
    case fps15

    /// 23.976 frames per second — NTSC film.
    case fps23_976

    /// 24 frames per second — Cinema.
    case fps24

    /// 25 frames per second — PAL broadcast.
    case fps25

    /// 29.97 frames per second — NTSC broadcast.
    case fps29_97

    /// 30 frames per second.
    case fps30

    /// 48 frames per second — HFR cinema.
    case fps48

    /// 50 frames per second — PAL high frame rate.
    case fps50

    /// 59.94 frames per second — NTSC high frame rate.
    case fps59_94

    /// 60 frames per second.
    case fps60

    /// 90 frames per second.
    case fps90

    /// 100 frames per second.
    case fps100

    /// 120 frames per second.
    case fps120

    /// 240 frames per second — Slow motion.
    case fps240

    /// A custom frame rate expressed in frames per second.
    case custom(Double)

    /// The numeric frame rate value in frames per second.
    public var value: Double {
        switch self {
        case .fps1: return 1
        case .fps15: return 15
        case .fps23_976: return 23.976
        case .fps24: return 24
        case .fps25: return 25
        case .fps29_97: return 29.97
        case .fps30: return 30
        case .fps48: return 48
        case .fps50: return 50
        case .fps59_94: return 59.94
        case .fps60: return 60
        case .fps90: return 90
        case .fps100: return 100
        case .fps120: return 120
        case .fps240: return 240
        case .custom(let fps): return fps
        }
    }
}
