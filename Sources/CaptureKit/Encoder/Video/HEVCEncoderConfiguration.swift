// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the HEVC/H.265 encoder via VideoToolbox.
public struct HEVCEncoderConfiguration: Sendable, Equatable {
    /// Encoding profile.
    public var profile: HEVCProfile
    /// Target bitrate in bits per second.
    public var bitrate: Int
    /// Bitrate control mode.
    public var bitrateMode: VideoBitrateMode
    /// Key frame interval in frames.
    public var keyFrameInterval: Int
    /// Whether to use B-frames.
    public var bFrames: Bool
    /// Real-time encoding mode.
    public var realTime: Bool
    /// HDR mode.
    public var hdrMode: HDRMode
    /// Whether to include alpha channel.
    public var alphaChannel: Bool

    /// Creates a new HEVC encoder configuration.
    public init(
        profile: HEVCProfile = .main,
        bitrate: Int = 5_000_000,
        bitrateMode: VideoBitrateMode = .average,
        keyFrameInterval: Int = 60,
        bFrames: Bool = true,
        realTime: Bool = true,
        hdrMode: HDRMode = .sdr,
        alphaChannel: Bool = false
    ) {
        self.profile = profile
        self.bitrate = bitrate
        self.bitrateMode = bitrateMode
        self.keyFrameInterval = keyFrameInterval
        self.bFrames = bFrames
        self.realTime = realTime
        self.hdrMode = hdrMode
        self.alphaChannel = alphaChannel
    }

    /// Validate HDR mode requires main10 or higher profile.
    public func validate() throws {
        if hdrMode != .sdr && profile == .main {
            throw CaptureError.encoderConfigurationFailed(
                codec: "hevc",
                reason: "HDR mode \(hdrMode.rawValue) requires Main10 or Main42210 profile"
            )
        }
    }

    /// SDR streaming 1080p — 5 Mbps, real-time.
    public static let streaming1080p = HEVCEncoderConfiguration(
        profile: .main, bitrate: 5_000_000,
        bitrateMode: .average, keyFrameInterval: 60,
        bFrames: true, realTime: true, hdrMode: .sdr
    )

    /// HDR10 4K — Main10 profile, 25 Mbps.
    public static let hdr4K = HEVCEncoderConfiguration(
        profile: .main10, bitrate: 25_000_000,
        bitrateMode: .average, keyFrameInterval: 60,
        bFrames: true, realTime: true, hdrMode: .hdr10
    )

    /// HLG broadcast — Main10 profile, 8 Mbps.
    public static let hlgBroadcast = HEVCEncoderConfiguration(
        profile: .main10, bitrate: 8_000_000,
        bitrateMode: .average, keyFrameInterval: 60,
        bFrames: true, realTime: true, hdrMode: .hlg
    )

    /// Screen recording — Main profile, 8 Mbps.
    public static let screenRecording = HEVCEncoderConfiguration(
        profile: .main, bitrate: 8_000_000,
        bitrateMode: .variable, keyFrameInterval: 120,
        bFrames: false, realTime: true, hdrMode: .sdr
    )
}
