// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// PCM byte order.
public enum PCMByteOrder: String, Sendable, CaseIterable {
    /// Native byte order (host platform).
    case native
    /// Big-endian (network byte order).
    case bigEndian
    /// Little-endian.
    case littleEndian
}

/// Configuration for the Linear PCM passthrough "encoder" (no compression).
public struct PCMEncoderConfiguration: Sendable, Equatable {
    /// Output sample rate.
    public var sampleRate: SampleRate
    /// Number of output channels.
    public var channelCount: Int
    /// Bit depth.
    public var bitDepth: AudioBitDepth
    /// Whether the output is interleaved.
    public var isInterleaved: Bool
    /// Byte order.
    public var byteOrder: PCMByteOrder

    /// Creates a new PCM encoder configuration.
    public init(
        sampleRate: SampleRate = .rate48000,
        channelCount: Int = 2,
        bitDepth: AudioBitDepth = .int24,
        isInterleaved: Bool = true,
        byteOrder: PCMByteOrder = .native
    ) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.bitDepth = bitDepth
        self.isInterleaved = isInterleaved
        self.byteOrder = byteOrder
    }

    /// Broadcast standard — 48 kHz, stereo, 24-bit.
    public static let broadcast = PCMEncoderConfiguration(
        sampleRate: .rate48000, channelCount: 2, bitDepth: .int24
    )

    /// CD quality — 44.1 kHz, stereo, 16-bit.
    public static let cdQuality = PCMEncoderConfiguration(
        sampleRate: .rate44100, channelCount: 2, bitDepth: .int16
    )
}
