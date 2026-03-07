// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AACEncoder")
struct AACEncoderTests {
    private func makeEncoder() -> AACEncoder {
        AACEncoder(configuration: .podcast)
    }

    private func makeBuffer() -> AudioBuffer {
        let format = AudioFormat(
            sampleRate: .rate48000,
            channelCount: 2,
            bitDepth: .int16
        )
        return AudioBuffer(
            data: Data(repeating: 0, count: 1024),
            format: format,
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 1
        )
    }

    @Test("codec is aac")
    func codecIsAAC() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .aac)
    }

    @Test("is hardware accelerated")
    func isHardwareAccelerated() {
        let encoder = makeEncoder()
        #expect(encoder.isHardwareAccelerated == true)
    }

    @Test("supported sample rates include 48kHz")
    func supportedSampleRatesInclude48kHz() {
        let encoder = makeEncoder()
        #expect(encoder.supportedSampleRates.contains(.rate48000))
    }

    @Test("supported channel counts includes stereo")
    func supportedChannelCountsIncludesStereo() {
        let encoder = makeEncoder()
        #expect(encoder.supportedChannelCounts.contains(2))
    }

    @Test("supported bit rates upper bound is 320000")
    func supportedBitRatesUpperBound() {
        let encoder = makeEncoder()
        #expect(encoder.supportedBitRates.upperBound == 320_000)
    }

    @Test("not configured initially")
    func notConfiguredInitially() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let configured = await encoder.isConfigured
        #expect(configured == false)
    }

    @Test("configure sets isConfigured")
    func configureSetsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(aac: .podcast)
        let configured = await encoder.isConfigured
        #expect(configured == true)
    }

    @Test("configure with AAC-specific config validates")
    func configureWithAACSpecificConfig() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let config = AACEncoderConfiguration(
            profile: .lc,
            bitrate: 128_000,
            bitrateMode: .constant,
            sampleRate: .rate48000,
            channelCount: 2
        )
        try await encoder.configure(aac: config)
        let configured = await encoder.isConfigured
        #expect(configured == true)
    }

    @Test("configure with invalid config throws")
    func configureWithInvalidConfigThrows() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let config = AACEncoderConfiguration(
            profile: .heV2,
            bitrate: 32_000,
            bitrateMode: .constant,
            sampleRate: .rate48000,
            channelCount: 1
        )
        await #expect(throws: (any Error).self) {
            try await encoder.configure(aac: config)
        }
    }

    @Test("encode before configure throws")
    func encodeBeforeConfigureThrows() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let buffer = makeBuffer()
        await #expect(throws: (any Error).self) {
            try await encoder.encode(buffer)
        }
    }

    @Test("reset clears isConfigured")
    func resetClearsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(aac: .podcast)
        await encoder.reset()
        let configured = await encoder.isConfigured
        #expect(configured == false)
    }

    @Test("encode returns buffer with aac codec")
    func encodeReturnsBufferWithAACCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(aac: .podcast)
        let buffer = makeBuffer()
        let result = try await encoder.encode(buffer)
        #expect(result.codec == .aac)
    }
}
