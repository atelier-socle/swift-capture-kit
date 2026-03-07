// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AV1EncoderConfiguration")
struct AV1EncoderConfigurationTests {
    @Test("default values")
    func defaultValues() {
        let config = AV1EncoderConfiguration()
        #expect(config.profile == .main)
        #expect(config.bitrate == 5_000_000)
        #expect(config.bitrateMode == .average)
        #expect(config.keyFrameInterval == 60)
        #expect(config.realTime == true)
    }

    @Test("streaming1080p preset")
    func streaming1080p() {
        let config = AV1EncoderConfiguration.streaming1080p
        #expect(config.bitrate == 4_000_000)
    }

    @Test("streaming4K preset")
    func streaming4K() {
        let config = AV1EncoderConfiguration.streaming4K
        #expect(config.bitrate == 15_000_000)
    }

    @Test("archive preset is not realTime")
    func archiveNotRealTime() {
        #expect(AV1EncoderConfiguration.archive.realTime == false)
        #expect(AV1EncoderConfiguration.archive.bitrate == 30_000_000)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = AV1EncoderConfiguration.streaming1080p
        let b = AV1EncoderConfiguration.streaming1080p
        #expect(a == b)
    }

    @Test("different configs not equal")
    func notEqual() {
        #expect(
            AV1EncoderConfiguration.streaming1080p
                != AV1EncoderConfiguration.archive
        )
    }
}
