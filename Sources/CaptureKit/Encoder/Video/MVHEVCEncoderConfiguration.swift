// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the MV-HEVC stereoscopic encoder via VideoToolbox.
/// Encodes left/right eye pairs for spatial video (Apple Vision Pro).
/// Requires Apple Silicon (M1+) or visionOS.
public struct MVHEVCEncoderConfiguration: Sendable, Equatable {
    /// Target bitrate in bits per second (both views combined).
    public var bitrate: Int
    /// Bitrate control mode.
    public var bitrateMode: VideoBitrateMode
    /// Key frame interval in frames.
    public var keyFrameInterval: Int
    /// Real-time encoding mode.
    public var realTime: Bool
    /// Horizontal field of view in degrees (for spatial metadata).
    public var horizontalFieldOfView: Double
    /// Baseline distance between cameras in millimeters.
    public var baselineDistance: Double

    /// Creates a new MV-HEVC encoder configuration.
    public init(
        bitrate: Int = 25_000_000,
        bitrateMode: VideoBitrateMode = .average,
        keyFrameInterval: Int = 60,
        realTime: Bool = true,
        horizontalFieldOfView: Double = 90.0,
        baselineDistance: Double = 63.5
    ) {
        self.bitrate = bitrate
        self.bitrateMode = bitrateMode
        self.keyFrameInterval = keyFrameInterval
        self.realTime = realTime
        self.horizontalFieldOfView = horizontalFieldOfView
        self.baselineDistance = baselineDistance
    }

    /// Spatial video — standard Apple Vision Pro recording parameters.
    public static let spatialVideo = MVHEVCEncoderConfiguration(
        bitrate: 25_000_000, bitrateMode: .average,
        keyFrameInterval: 60, realTime: true,
        horizontalFieldOfView: 90.0, baselineDistance: 63.5
    )

    /// High quality spatial — higher bitrate for archival.
    public static let spatialVideoHQ = MVHEVCEncoderConfiguration(
        bitrate: 40_000_000, bitrateMode: .variable,
        keyFrameInterval: 60, realTime: false,
        horizontalFieldOfView: 90.0, baselineDistance: 63.5
    )
}
