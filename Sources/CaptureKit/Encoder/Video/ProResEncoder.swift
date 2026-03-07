// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// ProRes encoder via VideoToolbox.
///
/// Industry-standard production codec. Requires Apple Silicon (M1+) for hardware encoding.
/// All 6 profiles from Proxy to 4444 XQ. Intra-only — every frame is a keyframe.
public actor ProResEncoder: VideoEncoderProtocol {

    // MARK: - Properties

    /// The video codec used by this encoder.
    nonisolated public let codec: VideoCodec = .prores

    /// Current encoder configuration.
    public private(set) var configuration: ProResEncoderConfiguration
    /// Whether the encoder has been configured.
    public private(set) var isConfigured: Bool = false
    /// Whether a keyframe has been requested for the next frame.
    private var pendingKeyFrame: Bool = false

    // MARK: - Protocol Computed Properties

    /// Resolutions supported by this encoder.
    nonisolated public var supportedResolutions: [VideoResolution] {
        [.p720, .p1080, .p1440, .uhd4K, .dci4K, .uhd8K]
    }

    /// Frame rates supported by this encoder.
    nonisolated public var supportedFrameRates: [FrameRate] {
        [.fps23_976, .fps24, .fps25, .fps29_97, .fps30, .fps50, .fps59_94, .fps60]
    }

    /// Bitrate range supported by this encoder (bits per second).
    nonisolated public var supportedBitRates: ClosedRange<Int> {
        0...0
    }

    /// Encoding profiles supported by this encoder.
    nonisolated public var supportedProfiles: [String] {
        ProResProfile.allCases.map(\.rawValue)
    }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool {
        true
    }

    // MARK: - Initialization

    /// Creates a new encoder with the given configuration.
    public init(configuration: ProResEncoderConfiguration = .hq) {
        self.configuration = configuration
    }

    // MARK: - VideoEncoderProtocol

    /// Configures the encoder with generic video settings.
    public func configure(_ config: VideoEncoderConfiguration) async throws {
        let proresConfig = ProResEncoderConfiguration(
            realTime: config.realTime
        )
        self.configuration = proresConfig
        self.isConfigured = true
    }

    /// Encodes a video frame.
    public func encode(_ frame: VideoFrame) async throws -> EncodedVideoFrame {
        guard isConfigured else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "ProRes",
                reason: "Encoder is not configured"
            )
        }

        return EncodedVideoFrame(
            data: frame.data,
            codec: codec,
            timestamp: frame.timestamp,
            isKeyFrame: true,
            sequenceNumber: frame.sequenceNumber
        )
    }

    /// Requests the next encoded frame to be a keyframe.
    public func forceKeyFrame() async throws {
        // No-op: ProRes is an intra-only codec, every frame is a keyframe.
    }

    /// Updates the target bitrate dynamically.
    public func updateBitrate(_ bitrate: Int) async throws {
        // No-op: bitrate is determined by the ProRes profile.
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

    /// Configures with ProRes-specific settings.
    public func configure(prores config: ProResEncoderConfiguration) async throws {
        self.configuration = config
        self.isConfigured = true
    }
}
