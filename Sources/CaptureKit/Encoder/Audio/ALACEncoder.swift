// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Apple Lossless Audio Codec (ALAC) encoder.
///
/// Lossless compression — preserves full audio quality.
/// Supports 16, 24, and 32-bit encoding at any sample rate up to 384 kHz.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor ALACEncoder: AudioEncoderProtocol {
    /// The audio codec used by this encoder.
    nonisolated public let codec: AudioCodec = .alac

    /// Current configuration.
    public private(set) var configuration: ALACEncoderConfiguration

    /// Whether the encoder is ready to encode.
    public private(set) var isConfigured: Bool = false

    /// The sample rates supported by this encoder.
    nonisolated public var supportedSampleRates: [SampleRate] {
        SampleRate.allCases
    }

    /// The channel counts supported by this encoder.
    nonisolated public var supportedChannelCounts: [Int] { Array(1...8) }

    /// The range of bitrates supported (lossless — no bitrate control).
    nonisolated public var supportedBitRates: ClosedRange<Int> { 0...0 }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool { false }

    /// The encoding provider (DI — defaults to real AudioToolbox).
    private let encoderProvider: any AudioEncoderProviding

    /// Creates a new ALAC encoder.
    public init(configuration: ALACEncoderConfiguration = .studioQuality) {
        self.configuration = configuration
        #if canImport(AudioToolbox)
            self.encoderProvider = AudioToolboxEncoder()
        #else
            self.encoderProvider = PassthroughAudioEncoder()
        #endif
    }

    /// Creates a new ALAC encoder with an injected encoding provider.
    init(
        configuration: ALACEncoderConfiguration = .studioQuality,
        encoderProvider: any AudioEncoderProviding
    ) {
        self.configuration = configuration
        self.encoderProvider = encoderProvider
    }

    /// Configures the encoder with a generic configuration.
    public func configure(_ config: AudioEncoderConfiguration) async throws {
        let alacConfig = ALACEncoderConfiguration(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount
        )
        self.configuration = alacConfig

        let inputFormat = AudioFormat(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount,
            channelLayout: config.channelCount == 1
                ? .mono : .stereo,
            bitDepth: .float32
        )
        try await encoderProvider.configure(
            inputFormat: inputFormat,
            outputCodec: .alac,
            bitrate: nil,
            sampleRate: config.sampleRate,
            channelCount: config.channelCount
        )
        self.isConfigured = true
    }

    /// Encodes a raw audio buffer.
    public func encode(_ buffer: AudioBuffer) async throws -> EncodedAudioBuffer {
        guard isConfigured else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "alac", reason: "Encoder not configured"
            )
        }
        let encoded = try await encoderProvider.encode(
            data: buffer.data, timestamp: buffer.timestamp)
        return EncodedAudioBuffer(
            data: encoded,
            codec: .alac,
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
                data: data, codec: .alac,
                timestamp: 0, duration: 0, sequenceNumber: -1
            )
        ]
    }

    /// Resets the encoder to its initial state.
    public func reset() async {
        await encoderProvider.reset()
        isConfigured = false
    }

    /// Configure with ALAC-specific configuration.
    public func configure(alac config: ALACEncoderConfiguration) async throws {
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
            outputCodec: .alac,
            bitrate: nil,
            sampleRate: config.sampleRate,
            channelCount: config.channelCount
        )
        self.isConfigured = true
    }
}
