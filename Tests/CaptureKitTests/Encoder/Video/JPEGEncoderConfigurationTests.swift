// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("JPEGEncoderConfiguration")
struct JPEGEncoderConfigurationTests {
    @Test("default quality is 0.85")
    func defaultQuality() {
        #expect(JPEGEncoderConfiguration().quality == 0.85)
    }

    @Test("highQuality preset has 0.95")
    func highQualityPreset() {
        #expect(JPEGEncoderConfiguration.highQuality.quality == 0.95)
    }

    @Test("lowBandwidth preset has 0.5")
    func lowBandwidthPreset() {
        #expect(JPEGEncoderConfiguration.lowBandwidth.quality == 0.5)
    }

    @Test("validate succeeds for quality 0.0 to 1.0")
    func validateSucceeds() throws {
        try JPEGEncoderConfiguration(quality: 0.0).validate()
        try JPEGEncoderConfiguration(quality: 0.5).validate()
        try JPEGEncoderConfiguration(quality: 1.0).validate()
    }

    @Test("validate throws for quality above 1.0")
    func validateThrowsAbove() {
        let config = JPEGEncoderConfiguration(quality: 1.1)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for negative quality")
    func validateThrowsNegative() {
        let config = JPEGEncoderConfiguration(quality: -0.1)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }
}
