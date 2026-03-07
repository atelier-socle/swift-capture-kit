// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the H.264/AVC encoder via VideoToolbox.
public struct H264EncoderConfiguration: Sendable, Equatable {
    /// Encoding profile.
    public var profile: H264Profile
    /// Encoding level (determines max resolution/bitrate).
    public var level: H264Level
    /// Target bitrate in bits per second.
    public var bitrate: Int
    /// Bitrate control mode.
    public var bitrateMode: VideoBitrateMode
    /// Key frame interval in frames (e.g., 60 = every 2s at 30fps).
    public var keyFrameInterval: Int
    /// Whether to use B-frames (not supported in Baseline profile).
    public var bFrames: Bool
    /// Entropy coding mode (CAVLC or CABAC).
    public var entropyMode: H264EntropyMode
    /// Real-time encoding mode (low latency, prioritizes speed over quality).
    public var realTime: Bool
    /// Maximum slice size in bytes for network-friendly NAL units (nil = no limit).
    public var maxSliceBytes: Int?

    /// Creates a new H.264 encoder configuration.
    public init(
        profile: H264Profile = .high,
        level: H264Level = .auto,
        bitrate: Int = 5_000_000,
        bitrateMode: VideoBitrateMode = .average,
        keyFrameInterval: Int = 60,
        bFrames: Bool = true,
        entropyMode: H264EntropyMode = .cabac,
        realTime: Bool = true,
        maxSliceBytes: Int? = nil
    ) {
        self.profile = profile
        self.level = level
        self.bitrate = bitrate
        self.bitrateMode = bitrateMode
        self.keyFrameInterval = keyFrameInterval
        self.bFrames = bFrames
        self.entropyMode = entropyMode
        self.realTime = realTime
        self.maxSliceBytes = maxSliceBytes
    }

    /// Validate profile/feature compatibility.
    public func validate() throws {
        if profile == .baseline && bFrames {
            throw CaptureError.encoderConfigurationFailed(
                codec: "h264",
                reason: "Baseline profile does not support B-frames"
            )
        }
        if profile == .baseline && entropyMode == .cabac {
            throw CaptureError.encoderConfigurationFailed(
                codec: "h264",
                reason: "Baseline profile does not support CABAC"
            )
        }
        guard bitrate > 0 else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "h264", reason: "Bitrate must be positive"
            )
        }
        guard keyFrameInterval > 0 else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "h264",
                reason: "Key frame interval must be positive"
            )
        }
    }

    /// Streaming 720p — Main profile, 2.5 Mbps.
    public static let streaming720p = H264EncoderConfiguration(
        profile: .main, level: .level31, bitrate: 2_500_000,
        bitrateMode: .average, keyFrameInterval: 60,
        bFrames: true, entropyMode: .cabac, realTime: true
    )

    /// Streaming 1080p — High profile, 4.5 Mbps.
    public static let streaming1080p = H264EncoderConfiguration(
        profile: .high, level: .level41, bitrate: 4_500_000,
        bitrateMode: .average, keyFrameInterval: 60,
        bFrames: true, entropyMode: .cabac, realTime: true
    )

    /// Low latency — Baseline profile, no B-frames, CAVLC.
    public static let lowLatency = H264EncoderConfiguration(
        profile: .baseline, level: .auto, bitrate: 2_000_000,
        bitrateMode: .constant, keyFrameInterval: 30,
        bFrames: false, entropyMode: .cavlc, realTime: true
    )

    /// Archive — High profile, high bitrate, quality-optimized.
    public static let archive = H264EncoderConfiguration(
        profile: .high, level: .auto, bitrate: 20_000_000,
        bitrateMode: .variable, keyFrameInterval: 60,
        bFrames: true, entropyMode: .cabac, realTime: false
    )
}
