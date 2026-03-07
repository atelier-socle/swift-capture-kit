// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the FLAC lossless encoder.
public struct FLACEncoderConfiguration: Sendable, Equatable {
    /// Output sample rate.
    public var sampleRate: SampleRate
    /// Number of output channels.
    public var channelCount: Int
    /// Bit depth.
    public var bitDepth: AudioBitDepth
    /// Compression level (0 = fastest, 8 = smallest, 5 = default).
    public var compressionLevel: Int

    /// Creates a new FLAC encoder configuration.
    public init(
        sampleRate: SampleRate = .rate48000,
        channelCount: Int = 2,
        bitDepth: AudioBitDepth = .int24,
        compressionLevel: Int = 5
    ) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.bitDepth = bitDepth
        self.compressionLevel = compressionLevel
    }

    /// Validate compression level is 0–8.
    public func validate() throws {
        guard (0...8).contains(compressionLevel) else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "flac",
                reason: "Compression level \(compressionLevel) is outside the valid range 0...8"
            )
        }
    }

    /// Fast encoding — level 0 (largest files, fastest encoding).
    public static let fast = FLACEncoderConfiguration(
        sampleRate: .rate48000, channelCount: 2,
        bitDepth: .int24, compressionLevel: 0
    )

    /// Balanced — level 5 (default).
    public static let balanced = FLACEncoderConfiguration(
        sampleRate: .rate48000, channelCount: 2,
        bitDepth: .int24, compressionLevel: 5
    )

    /// Maximum compression — level 8 (smallest files, slowest encoding).
    public static let maximum = FLACEncoderConfiguration(
        sampleRate: .rate48000, channelCount: 2,
        bitDepth: .int24, compressionLevel: 8
    )
}
