// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the ProRes encoder via VideoToolbox.
/// Requires Apple Silicon (M1 or later) for hardware encoding.
public struct ProResEncoderConfiguration: Sendable, Equatable {
    /// ProRes profile.
    public var profile: ProResProfile
    /// Real-time encoding (vs offline/quality-optimized).
    public var realTime: Bool

    /// Creates a new ProRes encoder configuration.
    public init(profile: ProResProfile = .hq, realTime: Bool = true) {
        self.profile = profile
        self.realTime = realTime
    }

    /// Proxy — lightweight editing proxy.
    public static let proxy = ProResEncoderConfiguration(
        profile: .proxy, realTime: true
    )
    /// LT — light editing.
    public static let lt = ProResEncoderConfiguration(
        profile: .lt, realTime: true
    )
    /// Standard — general production.
    public static let standard = ProResEncoderConfiguration(
        profile: .standard, realTime: true
    )
    /// HQ — high quality production.
    public static let hq = ProResEncoderConfiguration(
        profile: .hq, realTime: true
    )
    /// 4444 — with alpha channel, VFX/compositing.
    public static let p4444 = ProResEncoderConfiguration(
        profile: .p4444, realTime: true
    )
    /// 4444 XQ — highest quality, mastering.
    public static let p4444xq = ProResEncoderConfiguration(
        profile: .p4444xq, realTime: false
    )
}
