// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Identifies the color space applied to video content.
public enum ColorSpace: String, Sendable, CaseIterable {
    /// Standard RGB (IEC 61966-2-1).
    case srgb

    /// Display P3 — wide color gamut used by Apple displays.
    case displayP3

    /// ITU-R BT.709 — standard HD television.
    case bt709

    /// ITU-R BT.2020 — wide color gamut for UHD.
    case bt2020

    /// ITU-R BT.2100 with Perceptual Quantizer transfer function.
    case bt2100PQ

    /// ITU-R BT.2100 with Hybrid Log-Gamma transfer function.
    case bt2100HLG

    /// DCI-P3 — digital cinema color space.
    case dcip3

    /// Adobe RGB (1998) — wide gamut for print and photography.
    case adobeRGB
}
