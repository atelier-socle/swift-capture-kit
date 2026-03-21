// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite(
    "ALACEncoder",
    .enabled(if: !TestEnvironment.isCI, "Real AudioToolbox encoder hangs without audio services on CI"),
    .timeLimit(.minutes(1)))
struct ALACEncoderTests {
    private func makeEncoder() -> ALACEncoder {
        ALACEncoder(configuration: .studioQuality)
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

    @Test("codec is alac")
    func codecIsALAC() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .alac)
    }

    @Test("is not hardware accelerated")
    func isNotHardwareAccelerated() {
        let encoder = makeEncoder()
        #expect(encoder.isHardwareAccelerated == false)
    }

    @Test("supported sample rates includes all cases")
    func supportedSampleRatesIncludesAllCases() {
        let encoder = makeEncoder()
        #expect(
            encoder.supportedSampleRates == SampleRate.allCases
        )
    }

    @Test("supported bit rates is 0 for lossless")
    func supportedBitRatesIsZeroForLossless() {
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
        try await encoder.configure(alac: .studioQuality)
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

    @Test("encode returns buffer with alac codec")
    func encodeReturnsBufferWithALACCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(alac: .studioQuality)
        let buffer = makeBuffer()
        let result = try await encoder.encode(buffer)
        #expect(result.codec == .alac)
    }

    // MARK: - Generic configure path

    @Test("generic configure sets isConfigured")
    func genericConfigure() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let config = AudioEncoderConfiguration(
            bitrate: 0,
            sampleRate: .rate48000,
            channelCount: 2
        )
        try await encoder.configure(config)
        #expect(await encoder.isConfigured == true)
    }

    // MARK: - Flush / Reset

    @Test("flush returns empty when no data buffered")
    func flushReturnsEmpty() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(alac: .studioQuality)
        let result = try await encoder.flush()
        #expect(result.isEmpty)
    }

    @Test("reset clears isConfigured")
    func resetClearsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(alac: .studioQuality)
        #expect(await encoder.isConfigured == true)
        await encoder.reset()
        #expect(await encoder.isConfigured == false)
    }

    // MARK: - Supported channels

    @Test("supports up to 8 channels")
    func supportsUpTo8Channels() {
        let encoder = makeEncoder()
        #expect(encoder.supportedChannelCounts == Array(1...8))
    }
}
