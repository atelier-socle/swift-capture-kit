// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockAudioEncoder: AudioEncoderProtocol {
    let codec: AudioCodec
    let supportedSampleRates: [SampleRate]
    let supportedChannelCounts: [Int]
    let supportedBitRates: ClosedRange<Int>
    let isHardwareAccelerated: Bool

    private(set) var configureCallCount = 0
    private(set) var encodeCallCount = 0
    private(set) var flushCallCount = 0
    private(set) var resetCallCount = 0

    private var _configuration: AudioEncoderConfiguration?

    init(
        codec: AudioCodec = .aac,
        supportedSampleRates: [SampleRate] = [.rate44100, .rate48000],
        supportedChannelCounts: [Int] = [1, 2],
        supportedBitRates: ClosedRange<Int> = 64_000...320_000,
        isHardwareAccelerated: Bool = false
    ) {
        self.codec = codec
        self.supportedSampleRates = supportedSampleRates
        self.supportedChannelCounts = supportedChannelCounts
        self.supportedBitRates = supportedBitRates
        self.isHardwareAccelerated = isHardwareAccelerated
    }

    func configure(_ config: AudioEncoderConfiguration) async throws {
        configureCallCount += 1
        _configuration = config
    }

    func encode(_ buffer: AudioBuffer) async throws -> EncodedAudioBuffer {
        encodeCallCount += 1
        return EncodedAudioBuffer(
            data: buffer.data,
            codec: codec,
            timestamp: buffer.timestamp,
            duration: buffer.duration,
            sequenceNumber: buffer.sequenceNumber
        )
    }

    func flush() async throws -> [EncodedAudioBuffer] {
        flushCallCount += 1
        return []
    }

    func reset() async {
        resetCallCount += 1
        _configuration = nil
    }
}
