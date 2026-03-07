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
    }
#endif
