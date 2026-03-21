// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if os(macOS)
    import Foundation
    import Testing
    @testable import CaptureKit

    @Suite("MP3Encoder")
    struct MP3EncoderTests {
        private func makeEncoder() -> MP3Encoder {
            MP3Encoder(
                configuration: .standard,
                encoderProvider: PassthroughAudioEncoder()
            )
        }

        @Test("codec is mp3")
        func codecIsMP3() {
            let encoder = makeEncoder()
            #expect(encoder.codec == .mp3)
        }

        @Test("is not hardware accelerated")
        func isNotHardwareAccelerated() {
            let encoder = makeEncoder()
            #expect(encoder.isHardwareAccelerated == false)
        }

        @Test("supports mono and stereo only")
        func supportsMonoAndStereoOnly() {
            let encoder = makeEncoder()
            #expect(encoder.supportedChannelCounts == [1, 2])
        }

        @Test("bitrate range is 32k-320k")
        func bitrateRange() {
            let encoder = makeEncoder()
            #expect(encoder.supportedBitRates == 32_000...320_000)
        }

        @Test("not configured initially")
        func notConfiguredInitially() async {
            guard #available(macOS 14.0, *) else { return }
            let encoder = makeEncoder()
            let configured = await encoder.isConfigured
            #expect(configured == false)
        }

        @Test("configure sets isConfigured")
        func configureSetsIsConfigured() async throws {
            guard #available(macOS 14.0, *) else { return }
            let encoder = makeEncoder()
            try await encoder.configure(mp3: .standard)
            let configured = await encoder.isConfigured
            #expect(configured == true)
        }

        // MARK: - Generic configure path

        @Test("generic configure sets isConfigured")
        func genericConfigureSetsIsConfigured() async throws {
            guard #available(macOS 14.0, *) else { return }
            let encoder = makeEncoder()
            let config = AudioEncoderConfiguration(
                bitrate: 192_000,
                sampleRate: .rate44100,
                channelCount: 2
            )
            try await encoder.configure(config)
            let configured = await encoder.isConfigured
            #expect(configured == true)
        }

        @Test("generic configure with mono uses mono layout")
        func genericConfigureMono() async throws {
            guard #available(macOS 14.0, *) else { return }
            let provider = MockAudioEncoderProvider()
            let encoder = MP3Encoder(
                configuration: .standard,
                encoderProvider: provider
            )
            let config = AudioEncoderConfiguration(
                bitrate: 128_000,
                sampleRate: .rate48000,
                channelCount: 1
            )
            try await encoder.configure(config)
            #expect(await provider.configureCallCount == 1)
        }

        // MARK: - Encode / Flush / Reset

        @Test("encode before configure throws")
        func encodeBeforeConfigureThrows() async {
            guard #available(macOS 14.0, *) else { return }
            let encoder = makeEncoder()
            let buffer = CaptureKit.AudioBuffer(
                data: Data(repeating: 0, count: 1024),
                format: AudioFormat(
                    sampleRate: .rate48000, channelCount: 1),
                timestamp: 0.0,
                duration: 0.02,
                sequenceNumber: 0
            )
            await #expect(throws: CaptureError.self) {
                try await encoder.encode(buffer)
            }
        }

        @Test("encode returns buffer with mp3 codec")
        func encodeReturnsMP3Codec() async throws {
            guard #available(macOS 14.0, *) else { return }
            let encoder = makeEncoder()
            try await encoder.configure(mp3: .standard)
            let buffer = CaptureKit.AudioBuffer(
                data: Data(repeating: 0xAA, count: 1024),
                format: AudioFormat(
                    sampleRate: .rate48000, channelCount: 2),
                timestamp: 1.0,
                duration: 0.02,
                sequenceNumber: 5
            )
            let encoded = try await encoder.encode(buffer)
            #expect(encoded.codec == .mp3)
            #expect(encoded.timestamp == 1.0)
            #expect(encoded.sequenceNumber == 5)
            #expect(encoded.data.count > 0)
        }

        @Test("flush returns empty when provider has no data")
        func flushReturnsEmpty() async throws {
            guard #available(macOS 14.0, *) else { return }
            let encoder = makeEncoder()
            try await encoder.configure(mp3: .standard)
            let result = try await encoder.flush()
            #expect(result.isEmpty)
        }

        @Test("reset clears isConfigured")
        func resetClearsIsConfigured() async throws {
            guard #available(macOS 14.0, *) else { return }
            let encoder = makeEncoder()
            try await encoder.configure(mp3: .standard)
            #expect(await encoder.isConfigured == true)
            await encoder.reset()
            #expect(await encoder.isConfigured == false)
        }

        // MARK: - Configuration Presets

        @Test("standard preset has 192k bitrate")
        func standardPreset() {
            let config = MP3EncoderConfiguration.standard
            #expect(config.bitrate == 192_000)
        }

        @Test("highQuality preset has 320k bitrate")
        func highQualityPreset() {
            let config = MP3EncoderConfiguration.highQuality
            #expect(config.bitrate == 320_000)
        }

        @Test("webRadio preset has 128k bitrate")
        func webRadioPreset() {
            let config = MP3EncoderConfiguration.webRadio
            #expect(config.bitrate == 128_000)
        }

        // MARK: - Configuration Validation

        @Test("configuration with 3 channels fails validation")
        func invalidChannelCount() {
            let config = MP3EncoderConfiguration(
                bitrate: 192_000,
                sampleRate: .rate48000,
                channelCount: 3
            )
            #expect(throws: CaptureError.self) {
                try config.validate()
            }
        }

        @Test("configuration with valid channels passes validation")
        func validChannelCount() throws {
            let config = MP3EncoderConfiguration(
                bitrate: 192_000,
                sampleRate: .rate48000,
                channelCount: 2
            )
            try config.validate()
        }

        // MARK: - Provider Error Propagation

        @Test("configure propagates provider error")
        func configurePropagatesToProviderError() async {
            guard #available(macOS 14.0, *) else { return }
            let provider = MockAudioEncoderProvider()
            await provider.setShouldThrowOnConfigure(true)
            let encoder = MP3Encoder(
                configuration: .standard,
                encoderProvider: provider
            )
            await #expect(throws: CaptureError.self) {
                try await encoder.configure(mp3: .standard)
            }
        }

        @Test("encode propagates provider error")
        func encodePropagatesToProviderError() async throws {
            guard #available(macOS 14.0, *) else { return }
            let provider = MockAudioEncoderProvider()
            let encoder = MP3Encoder(
                configuration: .standard,
                encoderProvider: provider
            )
            try await encoder.configure(mp3: .standard)
            await provider.setShouldThrowOnEncode(true)
            let buffer = CaptureKit.AudioBuffer(
                data: Data(repeating: 0, count: 1024),
                format: AudioFormat(
                    sampleRate: .rate48000, channelCount: 1),
                timestamp: 0.0,
                duration: 0.02,
                sequenceNumber: 0
            )
            await #expect(throws: CaptureError.self) {
                try await encoder.encode(buffer)
            }
        }

        // MARK: - Supported Sample Rates

        @Test("supported sample rates include common rates")
        func supportedSampleRates() {
            let encoder = makeEncoder()
            let rates = encoder.supportedSampleRates
            #expect(rates.contains(.rate44100))
            #expect(rates.contains(.rate48000))
            #expect(rates.contains(.rate22050))
        }

        // MARK: - Configuration property access

        @Test("configuration updates after configure")
        func configurationUpdatesAfterConfigure() async throws {
            guard #available(macOS 14.0, *) else { return }
            let encoder = makeEncoder()
            try await encoder.configure(mp3: .highQuality)
            let config = await encoder.configuration
            #expect(config.bitrate == 320_000)
        }
    }

#endif
