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

    /// The encoding provider (DI — defaults to real AudioToolbox).
    private let encoderProvider: any AudioEncoderProviding

    /// Creates a new AAC encoder.
    public init(configuration: AACEncoderConfiguration = .podcast) {
        self.configuration = configuration
        #if canImport(AudioToolbox)
            self.encoderProvider = AudioToolboxEncoder()
        #else
            self.encoderProvider = PassthroughAudioEncoder()
        #endif
    }

    /// Creates a new AAC encoder with an injected encoding provider.
    ///
    /// - Parameters:
    ///   - configuration: The encoder configuration.
    ///   - encoderProvider: The encoding provider to use.
    init(
        configuration: AACEncoderConfiguration = .podcast,
        encoderProvider: any AudioEncoderProviding
    ) {
        self.configuration = configuration
        self.encoderProvider = encoderProvider
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

        let inputFormat = AudioFormat(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount,
            channelLayout: config.channelCount == 1
                ? .mono : .stereo,
            bitDepth: .float32
        )
        try await encoderProvider.configure(
            inputFormat: inputFormat,
            outputCodec: .aac,
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
                codec: "aac", reason: "Encoder not configured"
            )
        }
        let (encoded, packetSizes) = try await encoderProvider.encode(
            data: buffer.data, timestamp: buffer.timestamp)
        return EncodedAudioBuffer(
            data: encoded,
            codec: .aac,
            timestamp: buffer.timestamp,
            duration: buffer.duration,
            sequenceNumber: buffer.sequenceNumber,
            packetSizes: packetSizes
        )
    }

    /// Flushes any buffered data from the encoder.
    public func flush() async throws -> [EncodedAudioBuffer] {
        guard let data = try await encoderProvider.flush() else {
            return []
        }
        return [
            EncodedAudioBuffer(
                data: data, codec: .aac,
                timestamp: 0, duration: 0, sequenceNumber: -1
            )
        ]
    }

    /// Resets the encoder to its initial state.
    public func reset() async {
        await encoderProvider.reset()
        isConfigured = false
    }

    /// Configure with AAC-specific configuration.
    public func configure(aac config: AACEncoderConfiguration) async throws {
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
            outputCodec: .aac,
            bitrate: config.bitrate,
            sampleRate: config.sampleRate,
            channelCount: config.channelCount
        )
        self.isConfigured = true
    }
}
