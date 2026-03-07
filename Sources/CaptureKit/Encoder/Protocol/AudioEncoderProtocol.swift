// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration parameters for an audio encoder.
public struct AudioEncoderConfiguration: Sendable, Equatable {
    /// The target bitrate in bits per second.
    public var bitrate: Int

    /// The sample rate for the encoded audio.
    public var sampleRate: SampleRate

    /// The number of audio channels to encode.
    public var channelCount: Int

    /// Creates a new audio encoder configuration.
    ///
    /// - Parameters:
    ///   - bitrate: The target bitrate in bits per second.
    ///   - sampleRate: The sample rate.
    ///   - channelCount: The number of channels.
    public init(bitrate: Int, sampleRate: SampleRate, channelCount: Int) {
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.channelCount = channelCount
    }
}

/// Protocol for audio encoders that compress raw audio buffers.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public protocol AudioEncoderProtocol: Sendable {
    /// The audio codec used by this encoder.
    var codec: AudioCodec { get }

    /// The sample rates supported by this encoder.
    var supportedSampleRates: [SampleRate] { get }

    /// The channel counts supported by this encoder.
    var supportedChannelCounts: [Int] { get }

    /// The range of bitrates supported by this encoder in bits per second.
    var supportedBitRates: ClosedRange<Int> { get }

    /// Whether this encoder uses hardware acceleration.
    var isHardwareAccelerated: Bool { get }

    /// Configures the encoder with the given configuration.
    ///
    /// - Parameter config: The desired encoder configuration.
    func configure(_ config: AudioEncoderConfiguration) async throws

    /// Encodes a raw audio buffer into an encoded audio buffer.
    ///
    /// - Parameter buffer: The raw audio buffer to encode.
    /// - Returns: The encoded audio buffer.
    func encode(_ buffer: AudioBuffer) async throws -> EncodedAudioBuffer

    /// Flushes any buffered data and returns remaining encoded buffers.
    ///
    /// - Returns: An array of any remaining encoded audio buffers.
    func flush() async throws -> [EncodedAudioBuffer]

    /// Resets the encoder to its initial state.
    func reset() async
}
