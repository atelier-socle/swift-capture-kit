// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Represents the type of an audio capture source.
public enum AudioSourceType: String, Sendable, CaseIterable {
    /// A microphone input.
    case microphone

    /// A line-in audio input.
    case lineIn

    /// System-level audio capture.
    case systemAudio

    /// A Bluetooth audio device.
    case bluetooth

    /// An aggregate audio device combining multiple inputs.
    case aggregate

    /// An audio file used as a capture source.
    case file

    /// A VoIP audio source.
    case voip

    /// A programmatic audio signal generator.
    case generator
}

/// Configuration for an audio capture source.
public struct AudioSourceConfiguration: Sendable, Equatable {
    /// The sample rate for the audio source.
    public var sampleRate: SampleRate

    /// The number of audio channels to capture.
    public var channelCount: Int

    /// The spatial arrangement of the audio channels, if applicable.
    public var channelLayout: ChannelLayout?

    /// The bit depth and numeric format of audio samples.
    public var bitDepth: AudioBitDepth

    /// The preferred buffer duration in seconds.
    public var preferredBufferDuration: TimeInterval

    /// Default configuration: 48 kHz, stereo, float32, 20 ms buffers.
    public static let `default` = AudioSourceConfiguration(
        sampleRate: .rate48000,
        channelCount: 2,
        channelLayout: .stereo,
        bitDepth: .float32,
        preferredBufferDuration: 0.02
    )

    /// Broadcast configuration: 48 kHz, stereo, float32, 10 ms buffers.
    public static let broadcast = AudioSourceConfiguration(
        sampleRate: .rate48000,
        channelCount: 2,
        channelLayout: .stereo,
        bitDepth: .float32,
        preferredBufferDuration: 0.01
    )

    /// High-resolution configuration: 96 kHz, stereo, float32, 20 ms buffers.
    public static let highResolution = AudioSourceConfiguration(
        sampleRate: .rate96000,
        channelCount: 2,
        channelLayout: .stereo,
        bitDepth: .float32,
        preferredBufferDuration: 0.02
    )

    /// Spatial audio configuration: 48 kHz, 4-channel ambisonic FOA, float32, 20 ms buffers.
    public static let spatialAudio = AudioSourceConfiguration(
        sampleRate: .rate48000,
        channelCount: 4,
        channelLayout: .ambisonicFOA,
        bitDepth: .float32,
        preferredBufferDuration: 0.02
    )

    /// Creates a new audio source configuration.
    ///
    /// - Parameters:
    ///   - sampleRate: The sample rate.
    ///   - channelCount: The number of audio channels.
    ///   - channelLayout: The spatial channel layout. Defaults to `nil`.
    ///   - bitDepth: The bit depth. Defaults to `.float32`.
    ///   - preferredBufferDuration: The preferred buffer duration in seconds. Defaults to `0.02`.
    public init(
        sampleRate: SampleRate,
        channelCount: Int,
        channelLayout: ChannelLayout? = nil,
        bitDepth: AudioBitDepth = .float32,
        preferredBufferDuration: TimeInterval = 0.02
    ) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.channelLayout = channelLayout
        self.bitDepth = bitDepth
        self.preferredBufferDuration = preferredBufferDuration
    }
}

/// Audio level measurement sample with per-channel detail.
public struct AudioLevelSample: Sendable {
    /// The timestamp of the measurement in seconds.
    public let timestamp: TimeInterval

    /// The peak level across all channels in decibels.
    public let peakLevel: Float

    /// The RMS level across all channels in decibels.
    public let rmsLevel: Float

    /// Per-channel audio level measurements.
    public let channels: [ChannelLevel]

    /// The momentary loudness in LUFS, if available.
    public let momentaryLoudness: Double?

    /// The short-term loudness in LUFS, if available.
    public let shortTermLoudness: Double?

    /// The integrated loudness in LUFS, if available.
    public let integratedLoudness: Double?

    /// The true peak level in dBTP, if available.
    public let truePeak: Float?

    /// The loudness range in LU, if available.
    public let loudnessRange: Double?

    /// Creates a new audio level sample.
    ///
    /// - Parameters:
    ///   - timestamp: The timestamp in seconds.
    ///   - peakLevel: The peak level in decibels.
    ///   - rmsLevel: The RMS level in decibels.
    ///   - channels: Per-channel level measurements.
    ///   - momentaryLoudness: The momentary loudness in LUFS. Defaults to `nil`.
    ///   - shortTermLoudness: The short-term loudness in LUFS. Defaults to `nil`.
    ///   - integratedLoudness: The integrated loudness in LUFS. Defaults to `nil`.
    ///   - truePeak: The true peak level in dBTP. Defaults to `nil`.
    ///   - loudnessRange: The loudness range in LU. Defaults to `nil`.
    public init(
        timestamp: TimeInterval,
        peakLevel: Float,
        rmsLevel: Float,
        channels: [ChannelLevel],
        momentaryLoudness: Double? = nil,
        shortTermLoudness: Double? = nil,
        integratedLoudness: Double? = nil,
        truePeak: Float? = nil,
        loudnessRange: Double? = nil
    ) {
        self.timestamp = timestamp
        self.peakLevel = peakLevel
        self.rmsLevel = rmsLevel
        self.channels = channels
        self.momentaryLoudness = momentaryLoudness
        self.shortTermLoudness = shortTermLoudness
        self.integratedLoudness = integratedLoudness
        self.truePeak = truePeak
        self.loudnessRange = loudnessRange
    }
}

/// Audio level for a single channel.
public struct ChannelLevel: Sendable, Equatable {
    /// The zero-based channel index.
    public let channel: Int

    /// The peak level for this channel in decibels.
    public let peak: Float

    /// The RMS level for this channel in decibels.
    public let rms: Float

    /// Creates a new channel level measurement.
    ///
    /// - Parameters:
    ///   - channel: The zero-based channel index.
    ///   - peak: The peak level in decibels.
    ///   - rms: The RMS level in decibels.
    public init(channel: Int, peak: Float, rms: Float) {
        self.channel = channel
        self.peak = peak
        self.rms = rms
    }
}

/// Protocol for audio capture sources.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public protocol AudioSource: Sendable {
    /// A unique identifier for this audio source.
    var sourceID: String { get }

    /// A human-readable display name for this audio source.
    var displayName: String { get }

    /// The type of this audio source.
    var sourceType: AudioSourceType { get }

    /// The audio formats supported by this source.
    var supportedFormats: [AudioFormat] { get async }

    /// The currently active audio format, if any.
    var activeFormat: AudioFormat? { get async }

    /// Whether this source is currently capturing audio.
    var isCapturing: Bool { get async }

    /// The availability status of this source on the current platform and device.
    var availability: SourceAvailability { get }

    /// Configures this audio source with the given configuration.
    ///
    /// - Parameter configuration: The desired audio source configuration.
    func configure(_ configuration: AudioSourceConfiguration) async throws

    /// Starts capturing audio and returns an async stream of audio buffers.
    ///
    /// - Returns: An asynchronous stream of captured audio buffers.
    func startCapture() async throws -> AsyncStream<AudioBuffer>

    /// Stops the current audio capture.
    func stopCapture() async

    /// An asynchronous stream of audio level measurement samples.
    var audioLevel: AsyncStream<AudioLevelSample> { get }
}
