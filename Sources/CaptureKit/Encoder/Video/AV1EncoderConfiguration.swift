// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the AV1 encoder via VideoToolbox.
/// Requires Apple M3 or later for hardware encoding.
public struct AV1EncoderConfiguration: Sendable, Equatable {
    /// AV1 profile.
    public var profile: AV1Profile
    /// Target bitrate in bits per second.
    public var bitrate: Int
    /// Bitrate control mode.
    public var bitrateMode: VideoBitrateMode
    /// Key frame interval in frames.
    public var keyFrameInterval: Int
    /// Real-time encoding mode.
    public var realTime: Bool

    /// Creates a new AV1 encoder configuration.
    public init(
        profile: AV1Profile = .main,
        bitrate: Int = 5_000_000,
        bitrateMode: VideoBitrateMode = .average,
        keyFrameInterval: Int = 60,
        realTime: Bool = true
    ) {
        self.profile = profile
        self.bitrate = bitrate
        self.bitrateMode = bitrateMode
        self.keyFrameInterval = keyFrameInterval
        self.realTime = realTime
    }

    /// Streaming 1080p — 4 Mbps, real-time.
    public static let streaming1080p = AV1EncoderConfiguration(
        profile: .main, bitrate: 4_000_000,
        bitrateMode: .average, keyFrameInterval: 60, realTime: true
    )

    /// Streaming 4K — 15 Mbps, real-time.
    public static let streaming4K = AV1EncoderConfiguration(
        profile: .main, bitrate: 15_000_000,
        bitrateMode: .average, keyFrameInterval: 60, realTime: true
    )

    /// Archive — high quality offline encoding.
    public static let archive = AV1EncoderConfiguration(
        profile: .main, bitrate: 30_000_000,
        bitrateMode: .variable, keyFrameInterval: 120, realTime: false
    )
}
