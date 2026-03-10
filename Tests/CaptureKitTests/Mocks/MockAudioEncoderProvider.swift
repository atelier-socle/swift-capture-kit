// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

/// Mock audio encoder provider for testing without AudioToolbox.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockAudioEncoderProvider: AudioEncoderProviding {
    /// Number of configure() calls.
    var configureCallCount = 0

    /// Number of encode() calls.
    var encodeCallCount = 0

    /// Number of reset() calls.
    var resetCallCount = 0

    /// The last codec passed to configure().
    var lastOutputCodec: AudioCodec?

    /// The last bitrate passed to configure().
    var lastBitrate: Int?

    /// Whether configure() should throw.
    var shouldThrowOnConfigure = false

    /// Whether encode() should throw.
    var shouldThrowOnEncode = false

    func configure(
        inputFormat: AudioFormat,
        outputCodec: AudioCodec,
        bitrate: Int?,
        sampleRate: SampleRate,
        channelCount: Int
    ) async throws {
        configureCallCount += 1
        lastOutputCodec = outputCodec
        lastBitrate = bitrate
        if shouldThrowOnConfigure {
            throw CaptureError.encoderConfigurationFailed(
                codec: outputCodec.rawValue,
                reason: "Mock configure error"
            )
        }
    }

    func encode(
        data: Data, timestamp: TimeInterval
    ) async throws -> (Data, packetSizes: [Int]?) {
        encodeCallCount += 1
        if shouldThrowOnEncode {
            throw CaptureError.encodingFailed(
                codec: "mock",
                reason: "Mock encode error"
            )
        }
        return (data, packetSizes: nil)
    }

    func flush() async throws -> Data? { nil }

    func reset() async {
        resetCallCount += 1
    }
}
