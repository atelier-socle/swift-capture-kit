// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PCMEncoderConfiguration")
struct PCMEncoderConfigurationTests {
    @Test("default values")
    func defaultValues() {
        let config = PCMEncoderConfiguration()
        #expect(config.sampleRate == .rate48000)
        #expect(config.channelCount == 2)
        #expect(config.bitDepth == .int24)
        #expect(config.isInterleaved == true)
        #expect(config.byteOrder == .native)
    }

    @Test("broadcast preset")
    func broadcastPreset() {
        let config = PCMEncoderConfiguration.broadcast
        #expect(config.sampleRate == .rate48000)
        #expect(config.bitDepth == .int24)
    }

    @Test("cdQuality preset")
    func cdQualityPreset() {
        let config = PCMEncoderConfiguration.cdQuality
        #expect(config.sampleRate == .rate44100)
        #expect(config.bitDepth == .int16)
    }

    @Test("custom configuration")
    func customConfiguration() {
        let config = PCMEncoderConfiguration(
            sampleRate: .rate96000,
            channelCount: 8,
            bitDepth: .float32,
            isInterleaved: false,
            byteOrder: .bigEndian
        )
        #expect(config.sampleRate == .rate96000)
        #expect(config.channelCount == 8)
        #expect(config.bitDepth == .float32)
        #expect(config.isInterleaved == false)
        #expect(config.byteOrder == .bigEndian)
    }

    @Test("Equatable conformance")
    func equatable() {
        #expect(PCMEncoderConfiguration.broadcast == PCMEncoderConfiguration())
    }

    @Test("different configs are not equal")
    func notEqual() {
        #expect(
            PCMEncoderConfiguration.broadcast
                != PCMEncoderConfiguration.cdQuality
        )
    }
}
