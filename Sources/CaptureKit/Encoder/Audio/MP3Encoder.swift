// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// MP3 encoder (macOS only).
///
/// Encodes audio to MPEG-1 Audio Layer 3. macOS only — not available on iOS.
/// For cross-platform use, prefer AAC or Opus.
#if os(macOS)
    @available(macOS 14.0, *)
    public actor MP3Encoder: AudioEncoderProtocol {
        /// The audio codec used by this encoder.
        nonisolated public let codec: AudioCodec = .mp3

        /// Current configuration.
        public private(set) var configuration: MP3EncoderConfiguration

        /// Whether the encoder is ready to encode.
        public private(set) var isConfigured: Bool = false

        /// The sample rates supported by this encoder.
        nonisolated public var supportedSampleRates: [SampleRate] {
            [
                .rate8000, .rate11025, .rate16000, .rate22050,
                .rate32000, .rate44100, .rate48000
            ]
        }

        /// The channel counts supported by this encoder.
        nonisolated public var supportedChannelCounts: [Int] { [1, 2] }

        /// The range of bitrates supported.
        nonisolated public var supportedBitRates: ClosedRange<Int> {
            32_000...320_000
        }

        /// Whether this encoder uses hardware acceleration.
        nonisolated public var isHardwareAccelerated: Bool { false }

        /// Creates a new MP3 encoder.
        public init(configuration: MP3EncoderConfiguration = .standard) {
            self.configuration = configuration
        }

        /// Configures the encoder with a generic configuration.
        public func configure(_ config: AudioEncoderConfiguration) async throws {
            let mp3Config = MP3EncoderConfiguration(
                bitrate: config.bitrate,
                sampleRate: config.sampleRate,
                channelCount: config.channelCount
            )
            try mp3Config.validate()
            self.configuration = mp3Config
            self.isConfigured = true
        }

        /// Encodes a raw audio buffer.
        public func encode(_ buffer: AudioBuffer) async throws -> EncodedAudioBuffer {
            guard isConfigured else {
                throw CaptureError.encoderConfigurationFailed(
                    codec: "mp3", reason: "Encoder not configured"
                )
            }
            return EncodedAudioBuffer(
                data: buffer.data,
                codec: .mp3,
                timestamp: buffer.timestamp,
                duration: buffer.duration,
                sequenceNumber: buffer.sequenceNumber
            )
        }

        /// Flushes any buffered data.
        public func flush() async throws -> [EncodedAudioBuffer] { [] }

        /// Resets the encoder to its initial state.
        public func reset() async { isConfigured = false }

        /// Configure with MP3-specific configuration.
        public func configure(mp3 config: MP3EncoderConfiguration) async throws {
            try config.validate()
            self.configuration = config
            self.isConfigured = true
        }
    }
#endif
