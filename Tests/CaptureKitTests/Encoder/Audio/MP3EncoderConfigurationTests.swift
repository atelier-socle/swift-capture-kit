// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

#if os(macOS)
    @Suite("MP3EncoderConfiguration", .timeLimit(.minutes(1)))
    struct MP3EncoderConfigurationTests {
        @Test("standard preset values")
        func standardPreset() {
            let config = MP3EncoderConfiguration.standard
            #expect(config.bitrate == 192_000)
            #expect(config.bitrateMode == .constant)
            #expect(config.sampleRate == .rate44100)
            #expect(config.channelCount == 2)
        }

        @Test("highQuality preset has 320kbps")
        func highQualityPreset() {
            #expect(MP3EncoderConfiguration.highQuality.bitrate == 320_000)
        }

        @Test("webRadio preset has 128kbps")
        func webRadioPreset() {
            #expect(MP3EncoderConfiguration.webRadio.bitrate == 128_000)
        }

        @Test("validate succeeds for quality 0-9")
        func validateSucceeds() throws {
            for q in 0...9 {
                let config = MP3EncoderConfiguration(quality: q)
                try config.validate()
            }
        }

        @Test("validate throws for quality 10")
        func validateThrowsQuality10() {
            let config = MP3EncoderConfiguration(quality: 10)
            #expect(throws: CaptureError.self) {
                try config.validate()
            }
        }

        @Test("validate throws for channelCount > 2")
        func validateThrowsChannelCount3() {
            let config = MP3EncoderConfiguration(channelCount: 3)
            #expect(throws: CaptureError.self) {
                try config.validate()
            }
        }
    }
#endif
