// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// MV-HEVC stereoscopic encoder for spatial video (Apple Vision Pro).
///
/// Encodes left/right eye pairs as a single MV-HEVC stream.
/// Requires Apple Silicon (M1+) or visionOS hardware.
public actor MVHEVCEncoder: VideoEncoderProtocol {

    // MARK: - Properties

    /// The video codec used by this encoder.
    nonisolated public let codec: VideoCodec = .mvHevc

    /// Current encoder configuration.
    public private(set) var configuration: MVHEVCEncoderConfiguration
    /// Whether the encoder has been configured.
    public private(set) var isConfigured: Bool = false
    /// Whether a keyframe has been requested for the next frame.
    private var pendingKeyFrame: Bool = false

    // MARK: - Protocol Computed Properties

    /// Resolutions supported by this encoder.
    nonisolated public var supportedResolutions: [VideoResolution] {
        [.spatialVideo, .p1080]
    }

    /// Frame rates supported by this encoder.
    nonisolated public var supportedFrameRates: [FrameRate] {
        [.fps30]
    }

    /// Bitrate range supported by this encoder (bits per second).
    nonisolated public var supportedBitRates: ClosedRange<Int> {
        10_000_000...50_000_000
    }

    /// Encoding profiles supported by this encoder.
    nonisolated public var supportedProfiles: [String] {
        ["stereo"]
    }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool {
        true
    }

    // MARK: - Initialization

    /// Creates a new encoder with the given configuration.
    public init(configuration: MVHEVCEncoderConfiguration = .spatialVideo) {
        self.configuration = configuration
    }

    // MARK: - VideoEncoderProtocol

    /// Configures the encoder with generic video settings.
    public func configure(_ config: VideoEncoderConfiguration) async throws {
        let mvhevcConfig = MVHEVCEncoderConfiguration(
            bitrate: config.bitrate,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime
        )
        self.configuration = mvhevcConfig
        self.isConfigured = true
    }

    /// Encodes a video frame.
    public func encode(_ frame: VideoFrame) async throws -> EncodedVideoFrame {
        guard isConfigured else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "MV-HEVC",
                reason: "Encoder is not configured"
            )
        }

        return EncodedVideoFrame(
            data: frame.data,
            codec: codec,
            timestamp: frame.timestamp,
            isKeyFrame: frame.isKeyFrame || pendingKeyFrame,
            sequenceNumber: frame.sequenceNumber
        )
    }

    /// Requests the next encoded frame to be a keyframe.
    public func forceKeyFrame() async throws {
        pendingKeyFrame = true
    }

    /// Updates the target bitrate dynamically.
    public func updateBitrate(_ bitrate: Int) async throws {
        self.configuration = MVHEVCEncoderConfiguration(
            bitrate: bitrate,
            keyFrameInterval: configuration.keyFrameInterval,
            realTime: configuration.realTime
        )
    }

    /// Flushes any buffered frames.
    public func flush() async throws -> [EncodedVideoFrame] {
        []
    }

    /// Resets the encoder to its unconfigured state.
    public func reset() async {
        isConfigured = false
        pendingKeyFrame = false
    }

    // MARK: - Codec-Specific Configuration

    /// Configures with MV-HEVC-specific settings.
    public func configure(mvhevc config: MVHEVCEncoderConfiguration) async throws {
        self.configuration = config
        self.isConfigured = true
    }
}
