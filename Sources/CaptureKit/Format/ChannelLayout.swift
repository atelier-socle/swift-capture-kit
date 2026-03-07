// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Describes the spatial arrangement of audio channels in a stream.
public enum ChannelLayout: String, Sendable, CaseIterable {
    /// 1.0 — Single channel.
    case mono

    /// 2.0 — Left, Right.
    case stereo

    /// 2.1 — Left, Right, LFE.
    case stereoWithLFE

    /// 4.0 — Left, Right, Left Surround, Right Surround.
    case quadraphonic

    /// 5.0 — Left, Center, Right, Left Surround, Right Surround.
    case surround50

    /// 5.1 — Left, Center, Right, Left Surround, Right Surround, LFE.
    case surround51

    /// 6.1 — Left, Center, Right, Left Surround, Right Surround, Center Surround, LFE.
    case surround61

    /// 7.1 — Left, Center, Right, Left Side Surround, Right Side Surround, Left Surround, Right Surround, LFE.
    case surround71

    /// 7.1.4 — Dolby Atmos bed layout.
    case surround714

    /// First Order Ambisonics — 4 channels (W, X, Y, Z).
    case ambisonicFOA

    /// Second Order Ambisonics — 9 channels.
    case ambisonicSOA

    /// Third Order Ambisonics — 16 channels.
    case ambisonicTOA

    /// Binaural stereo — head-tracked two-channel rendering.
    case binaural

    /// The number of discrete audio channels in this layout.
    public var channelCount: Int {
        switch self {
        case .mono:
            return 1
        case .stereo:
            return 2
        case .stereoWithLFE:
            return 3
        case .quadraphonic:
            return 4
        case .surround50:
            return 5
        case .surround51:
            return 6
        case .surround61:
            return 7
        case .surround71:
            return 8
        case .surround714:
            return 12
        case .ambisonicFOA:
            return 4
        case .ambisonicSOA:
            return 9
        case .ambisonicTOA:
            return 16
        case .binaural:
            return 2
        }
    }
}
