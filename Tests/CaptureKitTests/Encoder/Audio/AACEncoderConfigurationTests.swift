// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AACEncoderConfiguration", .timeLimit(.minutes(1)))
struct AACEncoderConfigurationTests {
    @Test("default values")
    func defaultValues() {
        let config = AACEncoderConfiguration()
        #expect(config.profile == .lc)
        #expect(config.bitrate == 128_000)
        #expect(config.bitrateMode == .constant)
        #expect(config.sampleRate == .rate48000)
        #expect(config.channelCount == 2)
    }

    @Test("voice preset values")
    func voicePreset() {
        let config = AACEncoderConfiguration.voice
        #expect(config.profile == .lc)
        #expect(config.bitrate == 64_000)
        #expect(config.channelCount == 1)
    }

    @Test("podcast preset values")
    func podcastPreset() {
        let config = AACEncoderConfiguration.podcast
        #expect(config.profile == .lc)
        #expect(config.bitrate == 128_000)
        #expect(config.channelCount == 2)
    }

    @Test("musicHQ preset values")
    func musicHQPreset() {
        let config = AACEncoderConfiguration.musicHQ
        #expect(config.bitrate == 256_000)
        #expect(config.bitrateMode == .variable)
    }

    @Test("streamingLowBandwidth preset values")
    func streamingLowBandwidthPreset() {
        let config = AACEncoderConfiguration.streamingLowBandwidth
        #expect(config.profile == .heV1)
        #expect(config.bitrate == 64_000)
        #expect(config.sampleRate == .rate44100)
    }

    @Test("lowLatency preset values")
    func lowLatencyPreset() {
        let config = AACEncoderConfiguration.lowLatency
        #expect(config.profile == .eld)
        #expect(config.bitrate == 32_000)
        #expect(config.sampleRate == .rate16000)
        #expect(config.channelCount == 1)
    }

    @Test("validate succeeds for valid config")
    func validateSucceeds() throws {
        let config = AACEncoderConfiguration.podcast
        try config.validate()
    }

    @Test("validate throws for HE-AAC v2 with mono")
    func validateThrowsHEv2Mono() {
        let config = AACEncoderConfiguration(
            profile: .heV2, bitrate: 24_000, channelCount: 1
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for ELD with 6 channels")
    func validateThrowsELD6Channels() {
        let config = AACEncoderConfiguration(
            profile: .eld, bitrate: 64_000, channelCount: 6
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for bitrate below profile minimum")
    func validateThrowsBitrateBelowMin() {
        let config = AACEncoderConfiguration(
            profile: .lc, bitrate: 1_000
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for bitrate above profile maximum")
    func validateThrowsBitrateAboveMax() {
        let config = AACEncoderConfiguration(
            profile: .lc, bitrate: 500_000
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("Equatable conformance")
    func equatable() {
        let config1 = AACEncoderConfiguration.podcast
        let config2 = AACEncoderConfiguration.podcast
        #expect(config1 == config2)
        #expect(config1 != AACEncoderConfiguration.voice)
    }
}
