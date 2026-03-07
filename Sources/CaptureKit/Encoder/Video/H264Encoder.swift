// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// H.264/AVC encoder via VideoToolbox.
///
/// The most widely compatible video codec. Hardware-accelerated on all Apple devices.
/// Supports Baseline, Main, High, and High10 profiles with configurable entropy mode,
/// B-frames, and bitrate control.
public actor H264Encoder: VideoEncoderProtocol {

    // MARK: - Properties

    /// The video codec used by this encoder.
    nonisolated public let codec: VideoCodec = .h264

    /// Current encoder configuration.
    public private(set) var configuration: H264EncoderConfiguration
    /// Whether the encoder has been configured.
    public private(set) var isConfigured: Bool = false
    /// Whether a keyframe has been requested for the next frame.
    private var pendingKeyFrame: Bool = false
    /// The underlying encoder provider (VideoToolbox or passthrough).
    private let encoderProvider: any VideoEncoderProviding

    // MARK: - Protocol Computed Properties

    /// Resolutions supported by this encoder.
    nonisolated public var supportedResolutions: [VideoResolution] {
        [.qvga, .vga, .p540, .p720, .p1080, .p1440, .uhd4K]
    }

    /// Frame rates supported by this encoder.
    nonisolated public var supportedFrameRates: [FrameRate] {
        [.fps15, .fps24, .fps25, .fps29_97, .fps30, .fps50, .fps59_94, .fps60]
    }

    /// Bitrate range supported by this encoder (bits per second).
    nonisolated public var supportedBitRates: ClosedRange<Int> {
        100_000...100_000_000
    }

    /// Encoding profiles supported by this encoder.
    nonisolated public var supportedProfiles: [String] {
        H264Profile.allCases.map(\.rawValue)
    }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool {
        true
    }

    // MARK: - Initialization

    /// Creates a new encoder with the given configuration.
    public init(configuration: H264EncoderConfiguration = .streaming1080p) {
        self.configuration = configuration
        #if canImport(VideoToolbox)
            self.encoderProvider = VideoToolboxEncoder()
        #else
            self.encoderProvider = PassthroughVideoEncoder()
        #endif
    }

    /// Creates a new encoder with an injected provider (for testing).
    init(configuration: H264EncoderConfiguration = .streaming1080p, encoderProvider: any VideoEncoderProviding) {
        self.configuration = configuration
        self.encoderProvider = encoderProvider
    }

    // MARK: - VideoEncoderProtocol

    /// Configures the encoder with generic video settings.
    public func configure(_ config: VideoEncoderConfiguration) async throws {
        let h264Config = H264EncoderConfiguration(
            bitrate: config.bitrate,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime
        )
        try h264Config.validate()
        self.configuration = h264Config

        try await encoderProvider.configure(
            width: config.resolution.width,
            height: config.resolution.height,
            codec: .h264,
            bitrate: config.bitrate,
            frameRate: config.frameRate.value,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime,
            profileLevel: configuration.profile.rawValue
        )
        self.isConfigured = true
    }

    /// Encodes a video frame.
    public func encode(_ frame: VideoFrame) async throws -> EncodedVideoFrame {
        guard isConfigured else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "H.264",
                reason: "Encoder is not configured"
            )
        }

        let isKey = frame.isKeyFrame || pendingKeyFrame
        let encoded = try await encoderProvider.encode(
            data: frame.data,
            width: frame.format.resolution.width,
            height: frame.format.resolution.height,
            timestamp: frame.timestamp,
            isKeyFrame: isKey
        )
        pendingKeyFrame = false
        return EncodedVideoFrame(
            data: encoded,
            codec: codec,
            timestamp: frame.timestamp,
            isKeyFrame: isKey,
            sequenceNumber: frame.sequenceNumber
        )
    }

    /// Requests the next encoded frame to be a keyframe.
    public func forceKeyFrame() async throws {
        try await encoderProvider.forceKeyFrame()
        pendingKeyFrame = true
    }

    /// Updates the target bitrate dynamically.
    public func updateBitrate(_ bitrate: Int) async throws {
        try await encoderProvider.updateBitrate(bitrate)
        self.configuration = H264EncoderConfiguration(
            profile: configuration.profile,
            level: configuration.level,
            bitrate: bitrate,
            bitrateMode: configuration.bitrateMode,
            keyFrameInterval: configuration.keyFrameInterval,
            bFrames: configuration.bFrames,
            entropyMode: configuration.entropyMode,
            realTime: configuration.realTime,
            maxSliceBytes: configuration.maxSliceBytes
        )
    }

    /// Flushes any buffered frames.
    public func flush() async throws -> [EncodedVideoFrame] {
        guard let data = try await encoderProvider.flush() else {
            return []
        }
        return [
            EncodedVideoFrame(
                data: data, codec: codec,
                timestamp: 0, isKeyFrame: false, sequenceNumber: -1
            )
        ]
    }

    /// Resets the encoder to its unconfigured state.
    public func reset() async {
        await encoderProvider.reset()
        isConfigured = false
        pendingKeyFrame = false
    }

    // MARK: - Codec-Specific Configuration

    /// Configures with H.264-specific settings.
    public func configure(h264 config: H264EncoderConfiguration) async throws {
        try config.validate()
        self.configuration = config

        try await encoderProvider.configure(
            width: 1920, height: 1080,
            codec: .h264,
            bitrate: config.bitrate,
            frameRate: 30.0,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime,
            profileLevel: config.profile.rawValue
        )
        self.isConfigured = true
    }
}
