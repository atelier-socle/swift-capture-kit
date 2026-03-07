// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("OpusEncoderConfiguration")
struct OpusEncoderConfigurationTests {
    @Test("default values")
    func defaultValues() {
        let config = OpusEncoderConfiguration()
        #expect(config.bitrate == 128_000)
        #expect(config.bitrateMode == .variable)
        #expect(config.sampleRate == .rate48000)
        #expect(config.channelCount == 2)
        #expect(config.application == .audio)
    }

    @Test("voiceChat preset")
    func voiceChatPreset() {
        let config = OpusEncoderConfiguration.voiceChat
        #expect(config.bitrate == 32_000)
        #expect(config.channelCount == 1)
        #expect(config.application == .voip)
    }

    @Test("musicStreaming preset")
    func musicStreamingPreset() {
        let config = OpusEncoderConfiguration.musicStreaming
        #expect(config.bitrate == 128_000)
        #expect(config.application == .audio)
    }

    @Test("lowLatency preset")
    func lowLatencyPreset() {
        let config = OpusEncoderConfiguration.lowLatency
        #expect(config.bitrate == 64_000)
        #expect(config.bitrateMode == .constrained)
        #expect(config.application == .restrictedLowDelay)
    }

    @Test("validate succeeds for valid config")
    func validateSucceeds() throws {
        try OpusEncoderConfiguration.musicStreaming.validate()
    }

    @Test("validate throws for bitrate below 6000")
    func validateThrowsBitrateTooLow() {
        let config = OpusEncoderConfiguration(bitrate: 5_000)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for bitrate above 510000")
    func validateThrowsBitrateTooHigh() {
        let config = OpusEncoderConfiguration(bitrate: 600_000)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for channel count above 8")
    func validateThrowsChannelCountTooHigh() {
        let config = OpusEncoderConfiguration(channelCount: 9)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }
}
