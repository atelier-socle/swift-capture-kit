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

        /// The encoding provider (DI — defaults to real AudioToolbox).
        private let encoderProvider: any AudioEncoderProviding

        /// Creates a new MP3 encoder.
        public init(configuration: MP3EncoderConfiguration = .standard) {
            self.configuration = configuration
            #if canImport(AudioToolbox)
                self.encoderProvider = AudioToolboxEncoder()
            #else
                self.encoderProvider = PassthroughAudioEncoder()
            #endif
        }

        /// Creates a new MP3 encoder with an injected encoding provider.
        init(
            configuration: MP3EncoderConfiguration = .standard,
            encoderProvider: any AudioEncoderProviding
        ) {
            self.configuration = configuration
            self.encoderProvider = encoderProvider
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

            let inputFormat = AudioFormat(
                sampleRate: config.sampleRate,
                channelCount: config.channelCount,
                channelLayout: config.channelCount == 1
                    ? .mono : .stereo,
                bitDepth: .float32
            )
            try await encoderProvider.configure(
                inputFormat: inputFormat,
                outputCodec: .mp3,
                bitrate: config.bitrate,
                sampleRate: config.sampleRate,
                channelCount: config.channelCount
            )
            self.isConfigured = true
        }

        /// Encodes a raw audio buffer.
        public func encode(_ buffer: AudioBuffer) async throws -> EncodedAudioBuffer {
            guard isConfigured else {
                throw CaptureError.encoderConfigurationFailed(
                    codec: "mp3", reason: "Encoder not configured"
                )
            }
            let encoded = try await encoderProvider.encode(
                data: buffer.data, timestamp: buffer.timestamp)
            return EncodedAudioBuffer(
                data: encoded,
                codec: .mp3,
                timestamp: buffer.timestamp,
                duration: buffer.duration,
                sequenceNumber: buffer.sequenceNumber
            )
        }

        /// Flushes any buffered data from the encoder.
        public func flush() async throws -> [EncodedAudioBuffer] {
            guard let data = try await encoderProvider.flush() else {
                return []
            }
            return [
                EncodedAudioBuffer(
                    data: data, codec: .mp3,
                    timestamp: 0, duration: 0, sequenceNumber: -1
                )
            ]
        }

        /// Resets the encoder to its initial state.
        public func reset() async {
            await encoderProvider.reset()
            isConfigured = false
        }

        /// Configure with MP3-specific configuration.
        public func configure(mp3 config: MP3EncoderConfiguration) async throws {
            try config.validate()
            self.configuration = config

            let inputFormat = AudioFormat(
                sampleRate: config.sampleRate,
                channelCount: config.channelCount,
                channelLayout: config.channelCount == 1
                    ? .mono : .stereo,
                bitDepth: .float32
            )
            try await encoderProvider.configure(
                inputFormat: inputFormat,
                outputCodec: .mp3,
                bitrate: config.bitrate,
                sampleRate: config.sampleRate,
                channelCount: config.channelCount
            )
            self.isConfigured = true
        }
    }
#endif
