// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ALACEncoderConfiguration")
struct ALACEncoderConfigurationTests {
    @Test("default values")
    func defaultValues() {
        let config = ALACEncoderConfiguration()
        #expect(config.sampleRate == .rate48000)
        #expect(config.channelCount == 2)
        #expect(config.bitDepth == .int24)
    }

    @Test("cdQuality preset")
    func cdQualityPreset() {
        let config = ALACEncoderConfiguration.cdQuality
        #expect(config.sampleRate == .rate44100)
        #expect(config.channelCount == 2)
        #expect(config.bitDepth == .int16)
    }

    @Test("studioQuality preset")
    func studioQualityPreset() {
        let config = ALACEncoderConfiguration.studioQuality
        #expect(config.sampleRate == .rate96000)
        #expect(config.channelCount == 2)
        #expect(config.bitDepth == .int24)
    }

    @Test("custom configuration")
    func customConfiguration() {
        let config = ALACEncoderConfiguration(
            sampleRate: .rate192000, channelCount: 6, bitDepth: .int32
        )
        #expect(config.sampleRate == .rate192000)
        #expect(config.channelCount == 6)
        #expect(config.bitDepth == .int32)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = ALACEncoderConfiguration.cdQuality
        let b = ALACEncoderConfiguration.cdQuality
        #expect(a == b)
    }

    @Test("different configs are not equal")
    func notEqual() {
        #expect(
            ALACEncoderConfiguration.cdQuality
                != ALACEncoderConfiguration.studioQuality
        )
    }
}
