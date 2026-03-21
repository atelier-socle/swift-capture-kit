// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AudioEncoderProtocol", .timeLimit(.minutes(1)))
struct AudioEncoderProtocolTests {

    @Test("MockAudioEncoder conforms to AudioEncoderProtocol")
    func mockConformsToProtocol() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let encoder = MockAudioEncoder()
        #expect(encoder.codec == .aac)
        #expect(encoder.supportedSampleRates == [.rate44100, .rate48000])
        #expect(encoder.supportedChannelCounts == [1, 2])
        #expect(encoder.supportedBitRates == 64_000...320_000)
        #expect(encoder.isHardwareAccelerated == false)

        let config = AudioEncoderConfiguration(
            bitrate: 128_000,
            sampleRate: .rate48000,
            channelCount: 2
        )
        try await encoder.configure(config)
        let configCount = await encoder.configureCallCount
        #expect(configCount == 1)

        let format = AudioFormat(sampleRate: .rate48000, channelCount: 2)
        let buffer = AudioBuffer(
            data: Data([0x01]),
            format: format,
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 1
        )
        let encoded = try await encoder.encode(buffer)
        #expect(encoded.codec == .aac)
        let encodeCount = await encoder.encodeCallCount
        #expect(encodeCount == 1)

        let flushed = try await encoder.flush()
        #expect(flushed.isEmpty)
        let flushCount = await encoder.flushCallCount
        #expect(flushCount == 1)

        await encoder.reset()
        let resetCount = await encoder.resetCallCount
        #expect(resetCount == 1)
    }

    @Test("AudioEncoderConfiguration init stores properties")
    func configurationInit() {
        let config = AudioEncoderConfiguration(
            bitrate: 256_000,
            sampleRate: .rate44100,
            channelCount: 1
        )
        #expect(config.bitrate == 256_000)
        #expect(config.sampleRate == .rate44100)
        #expect(config.channelCount == 1)
    }

    @Test("AudioEncoderConfiguration Equatable")
    func configurationEquatable() {
        let a = AudioEncoderConfiguration(bitrate: 128_000, sampleRate: .rate48000, channelCount: 2)
        let b = AudioEncoderConfiguration(bitrate: 128_000, sampleRate: .rate48000, channelCount: 2)
        let c = AudioEncoderConfiguration(bitrate: 256_000, sampleRate: .rate48000, channelCount: 2)
        #expect(a == b)
        #expect(a != c)
    }
}
