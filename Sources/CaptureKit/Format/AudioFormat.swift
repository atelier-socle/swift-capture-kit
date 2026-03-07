// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// A complete description of an audio stream's sample format,
/// including rate, channels, bit depth, and interleaving.
public struct AudioFormat: Sendable, Equatable, Hashable {
    /// The number of samples per second.
    public let sampleRate: SampleRate

    /// The number of discrete audio channels.
    public let channelCount: Int

    /// The spatial arrangement of the channels, if known.
    public let channelLayout: ChannelLayout?

    /// The numeric format and precision of each audio sample.
    public let bitDepth: AudioBitDepth

    /// Whether sample data for multiple channels is interleaved
    /// in a single buffer (`true`) or provided in separate buffers (`false`).
    public let isInterleaved: Bool

    /// Creates a new audio format descriptor.
    ///
    /// - Parameters:
    ///   - sampleRate: The sample rate.
    ///   - channelCount: The number of audio channels.
    ///   - channelLayout: An optional channel layout describing the spatial
    ///     arrangement. Defaults to `nil`.
    ///   - bitDepth: The bit depth and numeric type. Defaults to `.float32`.
    ///   - isInterleaved: Whether sample data is interleaved. Defaults to `true`.
    public init(
        sampleRate: SampleRate,
        channelCount: Int,
        channelLayout: ChannelLayout? = nil,
        bitDepth: AudioBitDepth = .float32,
        isInterleaved: Bool = true
    ) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.channelLayout = channelLayout
        self.bitDepth = bitDepth
        self.isInterleaved = isInterleaved
    }
}
