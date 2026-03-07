// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PCMEncoder")
struct PCMEncoderTests {
    private func makeEncoder() -> PCMEncoder {
        PCMEncoder(configuration: .broadcast)
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

    @Test("codec is pcm")
    func codecIsPCM() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .pcm)
    }

    @Test("is not hardware accelerated")
    func isNotHardwareAccelerated() {
        let encoder = makeEncoder()
        #expect(encoder.isHardwareAccelerated == false)
    }

    @Test("supports up to 64 channels")
    func supportsUpTo64Channels() {
        let encoder = makeEncoder()
        #expect(encoder.supportedChannelCounts.contains(64))
        #expect(encoder.supportedChannelCounts.count == 64)
    }

    @Test("supported bit rates is 0 for uncompressed")
    func supportedBitRatesIsZeroForUncompressed() {
        let encoder = makeEncoder()
        #expect(encoder.supportedBitRates == 0...0)
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
        try await encoder.configure(pcm: .broadcast)
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

    @Test("encode returns buffer with pcm codec")
    func encodeReturnsBufferWithPCMCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(pcm: .broadcast)
        let buffer = makeBuffer()
        let result = try await encoder.encode(buffer)
        #expect(result.codec == .pcm)
    }
}
