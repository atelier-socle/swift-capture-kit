// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Represents standard audio sample rates used across various domains,
/// from telephony to ultra hi-res mastering.
public enum SampleRate: Double, Sendable, CaseIterable, Comparable {
    /// 8 000 Hz — Telephony.
    case rate8000 = 8000

    /// 11 025 Hz — Legacy.
    case rate11025 = 11025

    /// 16 000 Hz — Wideband voice.
    case rate16000 = 16000

    /// 22 050 Hz — AM radio.
    case rate22050 = 22050

    /// 24 000 Hz — Bluetooth HFP wideband.
    case rate24000 = 24000

    /// 32 000 Hz — Broadcast.
    case rate32000 = 32000

    /// 44 100 Hz — CD quality.
    case rate44100 = 44100

    /// 48 000 Hz — Broadcast / DVD / default.
    case rate48000 = 48000

    /// 88 200 Hz — Hi-res (2× CD).
    case rate88200 = 88200

    /// 96 000 Hz — Hi-res / professional.
    case rate96000 = 96000

    /// 176 400 Hz — Hi-res (4× CD).
    case rate176400 = 176400

    /// 192 000 Hz — Hi-res / mastering.
    case rate192000 = 192000

    /// 352 800 Hz — DSD-equivalent.
    case rate352800 = 352800

    /// 384 000 Hz — Ultra hi-res.
    case rate384000 = 384000

    /// Compares two sample rates by their underlying frequency value.
    public static func < (lhs: SampleRate, rhs: SampleRate) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
