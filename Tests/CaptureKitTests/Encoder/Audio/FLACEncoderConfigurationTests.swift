// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FLACEncoderConfiguration", .timeLimit(.minutes(1)))
struct FLACEncoderConfigurationTests {
    @Test("default compression level is 5")
    func defaultCompressionLevel() {
        let config = FLACEncoderConfiguration()
        #expect(config.compressionLevel == 5)
    }

    @Test("fast preset has level 0")
    func fastPreset() {
        #expect(FLACEncoderConfiguration.fast.compressionLevel == 0)
    }

    @Test("balanced preset has level 5")
    func balancedPreset() {
        #expect(FLACEncoderConfiguration.balanced.compressionLevel == 5)
    }

    @Test("maximum preset has level 8")
    func maximumPreset() {
        #expect(FLACEncoderConfiguration.maximum.compressionLevel == 8)
    }

    @Test("validate succeeds for level 0-8")
    func validateSucceeds() throws {
        for level in 0...8 {
            let config = FLACEncoderConfiguration(compressionLevel: level)
            try config.validate()
        }
    }

    @Test("validate throws for level 9")
    func validateThrowsLevel9() {
        let config = FLACEncoderConfiguration(compressionLevel: 9)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for negative level")
    func validateThrowsNegativeLevel() {
        let config = FLACEncoderConfiguration(compressionLevel: -1)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("Equatable conformance")
    func equatable() {
        #expect(FLACEncoderConfiguration.balanced == FLACEncoderConfiguration())
        #expect(FLACEncoderConfiguration.fast != FLACEncoderConfiguration.maximum)
    }
}
