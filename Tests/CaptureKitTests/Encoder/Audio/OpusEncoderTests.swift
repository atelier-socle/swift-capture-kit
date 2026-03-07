// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("OpusEncoder")
struct OpusEncoderTests {
    private func makeEncoder() -> OpusEncoder {
        OpusEncoder(configuration: .musicStreaming)
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

    @Test("codec is opus")
    func codecIsOpus() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .opus)
    }

    @Test("is not hardware accelerated")
    func isNotHardwareAccelerated() {
        let encoder = makeEncoder()
        #expect(encoder.isHardwareAccelerated == false)
    }

    @Test("supported sample rates include 48kHz")
    func supportedSampleRatesInclude48kHz() {
        let encoder = makeEncoder()
        #expect(encoder.supportedSampleRates.contains(.rate48000))
    }

    @Test("supported bit rates is 6000-510000")
    func supportedBitRatesRange() {
        let encoder = makeEncoder()
        #expect(encoder.supportedBitRates == 6_000...510_000)
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
        try await encoder.configure(opus: .musicStreaming)
        let configured = await encoder.isConfigured
        #expect(configured == true)
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

    @Test("encode returns buffer with opus codec")
    func encodeReturnsBufferWithOpusCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(opus: .musicStreaming)
        let buffer = makeBuffer()
        let result = try await encoder.encode(buffer)
        #expect(result.codec == .opus)
    }
}
