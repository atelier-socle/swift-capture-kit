// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Internal protocol abstracting audio encoding (AudioToolbox AudioConverter).
///
/// Enables dependency injection for testing: real implementation uses
/// AudioToolbox AudioConverter, tests inject a mock that returns data unchanged.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
protocol AudioEncoderProviding: Sendable {
    /// Configure the encoder with input and output format.
    ///
    /// - Parameters:
    ///   - inputFormat: The input audio format (typically PCM float32).
    ///   - outputCodec: The target codec for encoding.
    ///   - bitrate: The target bitrate in bits per second, if applicable.
    ///   - sampleRate: The output sample rate.
    ///   - channelCount: The output channel count.
    func configure(
        inputFormat: AudioFormat,
        outputCodec: AudioCodec,
        bitrate: Int?,
        sampleRate: SampleRate,
        channelCount: Int
    ) async throws

    /// Encode a buffer of PCM audio data.
    ///
    /// - Parameters:
    ///   - data: The raw PCM audio data.
    ///   - timestamp: The presentation timestamp in seconds.
    /// - Returns: The encoded audio data and optional per-packet sizes.
    ///   VBR codecs (AAC, Opus) return packet sizes so consumers can
    ///   identify individual access unit boundaries.
    func encode(
        data: Data, timestamp: TimeInterval
    ) async throws -> (Data, packetSizes: [Int]?)

    /// Flush any remaining encoded data.
    ///
    /// - Returns: Any remaining encoded data, or nil.
    func flush() async throws -> Data?

    /// Reset the encoder to its initial state.
    func reset() async
}

/// Passthrough encoder that returns data unchanged.
///
/// Used on platforms where AudioToolbox is not available,
/// or for PCM passthrough encoding.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
struct PassthroughAudioEncoder: AudioEncoderProviding {
    func configure(
        inputFormat: AudioFormat,
        outputCodec: AudioCodec,
        bitrate: Int?,
        sampleRate: SampleRate,
        channelCount: Int
    ) async throws {}

    func encode(
        data: Data, timestamp: TimeInterval
    ) async throws -> (Data, packetSizes: [Int]?) {
        (data, packetSizes: nil)
    }

    func flush() async throws -> Data? { nil }

    func reset() async {}
}
