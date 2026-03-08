// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Encodes raw PCM audio with a WAV (RIFF) container header.
///
/// Produces standard WAV files compatible with all audio software.
/// Unlike ``PCMEncoder`` (raw samples only), WAVEncoder adds the proper
/// RIFF/fmt/data headers for standalone file playback.
///
/// Pure Swift — no AudioToolbox dependency.
///
/// ```swift
/// let encoder = WAVEncoder()
/// try await encoder.configure(wav: WAVEncoderConfiguration(
///     sampleRate: .rate48000,
///     channelCount: 2,
///     bitDepth: .int24
/// ))
/// let encoded = try await encoder.encode(pcmBuffer)
/// // encoded.data contains WAV-wrapped data
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor WAVEncoder: AudioEncoderProtocol {
    /// The audio codec used by this encoder.
    nonisolated public let codec: AudioCodec = .pcm

    /// Current configuration.
    public private(set) var configuration: WAVEncoderConfiguration

    /// Whether the encoder has been configured.
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

    // MARK: - Private State

    private var sampleRate: Double = 48000
    private var channelCount: UInt16 = 2
    private var bitsPerSample: UInt16 = 16
    private var headerWritten: Bool = false
    private var totalDataBytes: UInt32 = 0

    // MARK: - Initialization

    /// Creates a new WAV encoder.
    public init(configuration: WAVEncoderConfiguration = .cdQuality) {
        self.configuration = configuration
    }

    // MARK: - AudioEncoderProtocol

    /// Configures the encoder with a generic configuration.
    public func configure(_ config: AudioEncoderConfiguration) async throws {
        let wavConfig = WAVEncoderConfiguration(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount
        )
        try await configure(wav: wavConfig)
    }

    /// Encodes a raw audio buffer by prepending the WAV header (first call)
    /// and passing through PCM data on subsequent calls.
    public func encode(_ buffer: AudioBuffer) async throws -> EncodedAudioBuffer {
        guard isConfigured else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "wav", reason: "Encoder not configured"
            )
        }

        var outputData = Data()

        if !headerWritten {
            outputData.append(buildWAVHeader())
            headerWritten = true
        }

        outputData.append(buffer.data)
        totalDataBytes += UInt32(buffer.data.count)

        return EncodedAudioBuffer(
            data: outputData,
            codec: .pcm,
            timestamp: buffer.timestamp,
            duration: buffer.duration,
            sequenceNumber: buffer.sequenceNumber
        )
    }

    /// Flushes the encoder, returning an updated WAV header with the final data size.
    ///
    /// The returned buffer has `sequenceNumber` set to `-1` to signal that it is
    /// a header update — consumers should overwrite the first 44 bytes of the file.
    public func flush() async throws -> [EncodedAudioBuffer] {
        guard headerWritten else { return [] }

        let finalHeader = buildWAVHeader(dataSize: totalDataBytes)
        return [
            EncodedAudioBuffer(
                data: finalHeader,
                codec: .pcm,
                timestamp: 0,
                duration: 0,
                sequenceNumber: -1
            )
        ]
    }

    /// Resets the encoder to its initial state.
    public func reset() async {
        isConfigured = false
        headerWritten = false
        totalDataBytes = 0
    }

    // MARK: - WAV-Specific Configuration

    /// Configures with WAV-specific settings.
    public func configure(wav config: WAVEncoderConfiguration) async throws {
        self.configuration = config
        self.sampleRate = config.sampleRate.rawValue
        self.channelCount = UInt16(config.channelCount)
        self.bitsPerSample = UInt16(config.bitDepth.byteSize * 8)
        self.headerWritten = false
        self.totalDataBytes = 0
        self.isConfigured = true
    }

    // MARK: - WAV Header (44 bytes, RIFF/WAVE/fmt/data)

    func buildWAVHeader(dataSize: UInt32 = 0) -> Data {
        let byteRate = UInt32(sampleRate) * UInt32(channelCount) * UInt32(bitsPerSample / 8)
        let blockAlign = channelCount * (bitsPerSample / 8)
        let fileSize = dataSize + 36  // 44 - 8 (RIFF header size field)

        var header = Data(capacity: 44)

        // RIFF chunk descriptor
        header.append(contentsOf: [0x52, 0x49, 0x46, 0x46])  // "RIFF"
        header.appendLittleEndian(fileSize)
        header.append(contentsOf: [0x57, 0x41, 0x56, 0x45])  // "WAVE"

        // fmt sub-chunk
        header.append(contentsOf: [0x66, 0x6D, 0x74, 0x20])  // "fmt "
        header.appendLittleEndian(UInt32(16))  // SubChunk1Size (PCM = 16)
        header.appendLittleEndian(UInt16(1))  // AudioFormat (PCM = 1)
        header.appendLittleEndian(channelCount)
        header.appendLittleEndian(UInt32(sampleRate))
        header.appendLittleEndian(byteRate)
        header.appendLittleEndian(blockAlign)
        header.appendLittleEndian(bitsPerSample)

        // data sub-chunk
        header.append(contentsOf: [0x64, 0x61, 0x74, 0x61])  // "data"
        header.appendLittleEndian(dataSize)

        return header
    }
}

extension Data {
    fileprivate mutating func appendLittleEndian(_ value: UInt16) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }

    fileprivate mutating func appendLittleEndian(_ value: UInt32) {
        Swift.withUnsafeBytes(of: value.littleEndian) { append(contentsOf: $0) }
    }
}
