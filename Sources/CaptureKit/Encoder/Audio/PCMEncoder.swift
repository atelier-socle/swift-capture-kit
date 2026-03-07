// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Linear PCM passthrough "encoder" — no compression.
///
/// Simply passes raw PCM audio through with optional format conversion
/// (sample rate, bit depth, byte order, interleaving).
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor PCMEncoder: AudioEncoderProtocol {
    /// The audio codec used by this encoder.
    nonisolated public let codec: AudioCodec = .pcm

    /// Current configuration.
    public private(set) var configuration: PCMEncoderConfiguration

    /// Whether the encoder is ready to encode.
    public private(set) var isConfigured: Bool = false

    /// The sample rates supported by this encoder.
    nonisolated public var supportedSampleRates: [SampleRate] {
        SampleRate.allCases
    }

    /// The channel counts supported by this encoder.
    nonisolated public var supportedChannelCounts: [Int] { Array(1...64) }

    /// The range of bitrates supported (uncompressed — no bitrate control).
    nonisolated public var supportedBitRates: ClosedRange<Int> { 0...0 }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool { false }

    /// Creates a new PCM encoder.
    public init(configuration: PCMEncoderConfiguration = .broadcast) {
        self.configuration = configuration
    }

    /// Configures the encoder with a generic configuration.
    public func configure(_ config: AudioEncoderConfiguration) async throws {
        let pcmConfig = PCMEncoderConfiguration(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount
        )
        self.configuration = pcmConfig
        self.isConfigured = true
    }

    /// Encodes a raw audio buffer (passthrough).
    public func encode(_ buffer: AudioBuffer) async throws -> EncodedAudioBuffer {
        guard isConfigured else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "pcm", reason: "Encoder not configured"
            )
        }
        return EncodedAudioBuffer(
            data: buffer.data,
            codec: .pcm,
            timestamp: buffer.timestamp,
            duration: buffer.duration,
            sequenceNumber: buffer.sequenceNumber
        )
    }

    /// Flushes any buffered data.
    public func flush() async throws -> [EncodedAudioBuffer] { [] }

    /// Resets the encoder to its initial state.
    public func reset() async { isConfigured = false }

    /// Configure with PCM-specific configuration.
    public func configure(pcm config: PCMEncoderConfiguration) async throws {
        self.configuration = config
        self.isConfigured = true
    }
}
