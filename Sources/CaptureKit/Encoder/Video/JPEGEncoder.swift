// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Motion JPEG encoder via VideoToolbox.
///
/// Each frame encoded independently — no inter-frame compression.
/// Very low latency but large output. Used for legacy systems,
/// monitoring feeds, and frame-by-frame editing.
public actor JPEGEncoder: VideoEncoderProtocol {

    // MARK: - Properties

    /// The video codec used by this encoder.
    nonisolated public let codec: VideoCodec = .jpeg

    /// Current encoder configuration.
    public private(set) var configuration: JPEGEncoderConfiguration
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
        [.fps1, .fps15, .fps24, .fps25, .fps30, .fps60]
    }

    /// Bitrate range supported by this encoder (bits per second).
    nonisolated public var supportedBitRates: ClosedRange<Int> {
        0...0
    }

    /// Encoding profiles supported by this encoder.
    nonisolated public var supportedProfiles: [String] {
        ["baseline"]
    }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool {
        true
    }

    // MARK: - Initialization

    /// Creates a new encoder with the given configuration.
    public init(configuration: JPEGEncoderConfiguration = .standard) {
        self.configuration = configuration
        #if canImport(VideoToolbox)
            self.encoderProvider = VideoToolboxEncoder()
        #else
            self.encoderProvider = PassthroughVideoEncoder()
        #endif
    }

    /// Creates a new encoder with an injected provider (for testing).
    init(configuration: JPEGEncoderConfiguration = .standard, encoderProvider: any VideoEncoderProviding) {
        self.configuration = configuration
        self.encoderProvider = encoderProvider
    }

    // MARK: - VideoEncoderProtocol

    /// Configures the encoder with generic video settings.
    public func configure(_ config: VideoEncoderConfiguration) async throws {
        let jpegConfig = JPEGEncoderConfiguration(
            realTime: config.realTime
        )
        try jpegConfig.validate()
        self.configuration = jpegConfig

        try await encoderProvider.configure(
            width: config.resolution.width,
            height: config.resolution.height,
            codec: .jpeg,
            bitrate: nil,
            frameRate: config.frameRate.value,
            keyFrameInterval: nil,
            realTime: config.realTime,
            profileLevel: nil
        )
        self.isConfigured = true
    }

    /// Encodes a video frame.
    public func encode(_ frame: VideoFrame) async throws -> EncodedVideoFrame {
        guard isConfigured else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "JPEG",
                reason: "Encoder is not configured"
            )
        }

        let encoded = try await encoderProvider.encode(
            data: frame.data,
            width: frame.format.resolution.width,
            height: frame.format.resolution.height,
            timestamp: frame.timestamp,
            isKeyFrame: true
        )
        return EncodedVideoFrame(
            data: encoded,
            codec: codec,
            timestamp: frame.timestamp,
            isKeyFrame: true,
            sequenceNumber: frame.sequenceNumber
        )
    }

    /// Requests the next encoded frame to be a keyframe.
    public func forceKeyFrame() async throws {
        // No-op: every frame is a keyframe in MJPEG.
        try await encoderProvider.forceKeyFrame()
    }

    /// Updates the target bitrate dynamically.
    public func updateBitrate(_ bitrate: Int) async throws {
        // No-op: JPEG is quality-based, not bitrate-based.
        try await encoderProvider.updateBitrate(bitrate)
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

    /// Configures with JPEG-specific settings.
    public func configure(jpeg config: JPEGEncoderConfiguration) async throws {
        try config.validate()
        self.configuration = config

        try await encoderProvider.configure(
            width: 1920, height: 1080,
            codec: .jpeg,
            bitrate: nil,
            frameRate: 30.0,
            keyFrameInterval: nil,
            realTime: config.realTime,
            profileLevel: nil
        )
        self.isConfigured = true
    }
}
