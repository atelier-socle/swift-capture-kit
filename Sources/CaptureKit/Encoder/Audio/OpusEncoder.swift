// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Opus encoder via AudioToolbox (macOS 14+ / iOS 17+).
///
/// Opus offers the best quality-to-bitrate ratio and lowest latency
/// of any audio codec. Ideal for voice chat, streaming, and low-latency applications.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor OpusEncoder: AudioEncoderProtocol {
    /// The audio codec used by this encoder.
    nonisolated public let codec: AudioCodec = .opus

    /// Current configuration.
    public private(set) var configuration: OpusEncoderConfiguration

    /// Whether the encoder is ready to encode.
    public private(set) var isConfigured: Bool = false

    /// The sample rates supported by this encoder.
    nonisolated public var supportedSampleRates: [SampleRate] {
        [.rate8000, .rate16000, .rate48000]
    }

    /// The channel counts supported by this encoder.
    nonisolated public var supportedChannelCounts: [Int] { Array(1...8) }

    /// The range of bitrates supported.
    nonisolated public var supportedBitRates: ClosedRange<Int> {
        6_000...510_000
    }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool { false }

    /// The encoding provider (DI — defaults to real AudioToolbox).
    private let encoderProvider: any AudioEncoderProviding

    /// Creates a new Opus encoder.
    public init(configuration: OpusEncoderConfiguration = .musicStreaming) {
        self.configuration = configuration
        #if canImport(AudioToolbox)
            self.encoderProvider = AudioToolboxEncoder()
        #else
            self.encoderProvider = PassthroughAudioEncoder()
        #endif
    }

    /// Creates a new Opus encoder with an injected encoding provider.
    init(
        configuration: OpusEncoderConfiguration = .musicStreaming,
        encoderProvider: any AudioEncoderProviding
    ) {
        self.configuration = configuration
        self.encoderProvider = encoderProvider
    }

    /// Configures the encoder with a generic configuration.
    public func configure(_ config: AudioEncoderConfiguration) async throws {
        let opusConfig = OpusEncoderConfiguration(
            bitrate: config.bitrate,
            sampleRate: config.sampleRate,
            channelCount: config.channelCount
        )
        try opusConfig.validate()
        self.configuration = opusConfig

        let inputFormat = AudioFormat(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount,
            channelLayout: config.channelCount == 1
                ? .mono : .stereo,
            bitDepth: .float32
        )
        try await encoderProvider.configure(
            inputFormat: inputFormat,
            outputCodec: .opus,
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
                codec: "opus", reason: "Encoder not configured"
            )
        }
        let (encoded, _) = try await encoderProvider.encode(
            data: buffer.data, timestamp: buffer.timestamp)
        return EncodedAudioBuffer(
            data: encoded,
            codec: .opus,
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
                data: data, codec: .opus,
                timestamp: 0, duration: 0, sequenceNumber: -1
            )
        ]
    }

    /// Resets the encoder to its initial state.
    public func reset() async {
        await encoderProvider.reset()
        isConfigured = false
    }

    /// Configure with Opus-specific configuration.
    public func configure(opus config: OpusEncoderConfiguration) async throws {
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
            outputCodec: .opus,
            bitrate: config.bitrate,
            sampleRate: config.sampleRate,
            channelCount: config.channelCount
        )
        self.isConfigured = true
    }
}
