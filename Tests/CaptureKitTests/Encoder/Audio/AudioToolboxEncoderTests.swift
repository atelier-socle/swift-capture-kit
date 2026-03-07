// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AudioToolboxEncoder")
struct AudioToolboxEncoderTests {

    @Test("AAC encoder uses mock provider")
    func aacEncoderUsesMockProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        let config = AudioEncoderConfiguration(
            bitrate: 128_000,
            sampleRate: .rate48000,
            channelCount: 2
        )
        try await encoder.configure(config)
        let count = await mock.configureCallCount
        #expect(count == 1)
        let codec = await mock.lastOutputCodec
        #expect(codec == .aac)
    }

    @Test("ALAC encoder uses mock provider")
    func alacEncoderUsesMockProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = ALACEncoder(
            configuration: .studioQuality,
            encoderProvider: mock
        )
        let config = AudioEncoderConfiguration(
            bitrate: 0,
            sampleRate: .rate48000,
            channelCount: 2
        )
        try await encoder.configure(config)
        let codec = await mock.lastOutputCodec
        #expect(codec == .alac)
    }

    @Test("Opus encoder uses mock provider")
    func opusEncoderUsesMockProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = OpusEncoder(
            configuration: .musicStreaming,
            encoderProvider: mock
        )
        let config = AudioEncoderConfiguration(
            bitrate: 128_000,
            sampleRate: .rate48000,
            channelCount: 2
        )
        try await encoder.configure(config)
        let codec = await mock.lastOutputCodec
        #expect(codec == .opus)
    }

    @Test("FLAC encoder uses mock provider")
    func flacEncoderUsesMockProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = FLACEncoder(
            configuration: .balanced, encoderProvider: mock)
        let config = AudioEncoderConfiguration(
            bitrate: 0,
            sampleRate: .rate48000,
            channelCount: 2
        )
        try await encoder.configure(config)
        let codec = await mock.lastOutputCodec
        #expect(codec == .flac)
    }

    @Test("encode calls provider encode")
    func encodeCallsProviderEncode() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        try await encoder.configure(aac: .podcast)
        let buffer = AudioBuffer(
            data: Data(repeating: 0, count: 256),
            format: AudioFormat(
                sampleRate: .rate48000, channelCount: 2),
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 0
        )
        _ = try await encoder.encode(buffer)
        let count = await mock.encodeCallCount
        #expect(count == 1)
    }

    @Test("encode before configure throws")
    func encodeBeforeConfigureThrows() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        let buffer = AudioBuffer(
            data: Data(count: 256),
            format: AudioFormat(
                sampleRate: .rate48000, channelCount: 2),
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 0
        )
        await #expect(throws: CaptureError.self) {
            _ = try await encoder.encode(buffer)
        }
    }

    @Test("reset calls provider reset")
    func resetCallsProviderReset() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        try await encoder.configure(aac: .podcast)
        await encoder.reset()
        let count = await mock.resetCallCount
        #expect(count == 1)
    }

    @Test("configure passes bitrate to provider")
    func configurePassesBitrate() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        let config = AudioEncoderConfiguration(
            bitrate: 256_000,
            sampleRate: .rate48000,
            channelCount: 2
        )
        try await encoder.configure(config)
        let bitrate = await mock.lastBitrate
        #expect(bitrate == 256_000)
    }

    @Test("provider configure error propagates")
    func providerConfigureErrorPropagates() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        await mock.setShouldThrowOnConfigure(true)
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(aac: .podcast)
        }
    }

    @Test("provider encode error propagates")
    func providerEncodeErrorPropagates() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        try await encoder.configure(aac: .podcast)
        await mock.setShouldThrowOnEncode(true)
        let buffer = AudioBuffer(
            data: Data(count: 256),
            format: AudioFormat(
                sampleRate: .rate48000, channelCount: 2),
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 0
        )
        await #expect(throws: CaptureError.self) {
            _ = try await encoder.encode(buffer)
        }
    }

    @Test("PCM encoder uses passthrough provider")
    func pcmEncoderUsesPassthrough() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let encoder = PCMEncoder()
        try await encoder.configure(pcm: .broadcast)
        let buffer = AudioBuffer(
            data: Data(repeating: 0x55, count: 512),
            format: AudioFormat(
                sampleRate: .rate48000, channelCount: 2),
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 0
        )
        let result = try await encoder.encode(buffer)
        #expect(result.data == Data(repeating: 0x55, count: 512))
        #expect(result.codec == .pcm)
    }

    @Test("passthrough encoder returns data unchanged")
    func passthroughReturnsUnchanged() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let provider = PassthroughAudioEncoder()
        let inputData = Data(repeating: 0x42, count: 1024)
        let output = try await provider.encode(
            data: inputData, timestamp: 0.0)
        #expect(output == inputData)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension MockAudioEncoderProvider {
    func setShouldThrowOnConfigure(_ value: Bool) {
        self.shouldThrowOnConfigure = value
    }

    func setShouldThrowOnEncode(_ value: Bool) {
        self.shouldThrowOnEncode = value
    }
}
