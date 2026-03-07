// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// AAC encoder with all profiles (LC, HE v1/v2, ELD, xHE).
///
/// Uses AudioToolbox's AudioConverter for hardware-accelerated encoding.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor AACEncoder: AudioEncoderProtocol {
    /// The audio codec used by this encoder.
    nonisolated public let codec: AudioCodec = .aac

    /// Current configuration.
    public private(set) var configuration: AACEncoderConfiguration

    /// Whether the encoder is ready to encode.
    public private(set) var isConfigured: Bool = false

    /// The sample rates supported by this encoder.
    nonisolated public var supportedSampleRates: [SampleRate] {
        [
            .rate8000, .rate11025, .rate16000, .rate22050, .rate32000,
            .rate44100, .rate48000, .rate88200, .rate96000
        ]
    }

    /// The channel counts supported by this encoder.
    nonisolated public var supportedChannelCounts: [Int] { Array(1...8) }

    /// The range of bitrates supported.
    nonisolated public var supportedBitRates: ClosedRange<Int> {
        8_000...320_000
    }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool { true }

    /// Creates a new AAC encoder.
    public init(configuration: AACEncoderConfiguration = .podcast) {
        self.configuration = configuration
    }

    /// Configures the encoder with a generic configuration.
    public func configure(_ config: AudioEncoderConfiguration) async throws {
        let aacConfig = AACEncoderConfiguration(
            profile: configuration.profile,
            bitrate: config.bitrate,
            bitrateMode: configuration.bitrateMode,
            sampleRate: config.sampleRate,
            channelCount: config.channelCount
        )
        try aacConfig.validate()
        self.configuration = aacConfig
        self.isConfigured = true
    }

    /// Encodes a raw audio buffer.
    public func encode(_ buffer: AudioBuffer) async throws -> EncodedAudioBuffer {
        guard isConfigured else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "aac", reason: "Encoder not configured"
            )
        }
        return EncodedAudioBuffer(
            data: buffer.data,
            codec: .aac,
            timestamp: buffer.timestamp,
            duration: buffer.duration,
            sequenceNumber: buffer.sequenceNumber
        )
    }

    /// Flushes any buffered data.
    public func flush() async throws -> [EncodedAudioBuffer] { [] }

    /// Resets the encoder to its initial state.
    public func reset() async { isConfigured = false }

    /// Configure with AAC-specific configuration.
    public func configure(aac config: AACEncoderConfiguration) async throws {
        try config.validate()
        self.configuration = config
        self.isConfigured = true
    }
}
