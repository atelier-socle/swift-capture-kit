// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("MVHEVCEncoderConfiguration")
struct MVHEVCEncoderConfigurationTests {
    @Test("default values")
    func defaultValues() {
        let config = MVHEVCEncoderConfiguration()
        #expect(config.bitrate == 25_000_000)
        #expect(config.horizontalFieldOfView == 90.0)
        #expect(config.baselineDistance == 63.5)
    }

    @Test("spatialVideo preset")
    func spatialVideoPreset() {
        let config = MVHEVCEncoderConfiguration.spatialVideo
        #expect(config.bitrate == 25_000_000)
        #expect(config.realTime == true)
    }

    @Test("spatialVideoHQ preset")
    func spatialVideoHQ() {
        let config = MVHEVCEncoderConfiguration.spatialVideoHQ
        #expect(config.bitrate == 40_000_000)
        #expect(config.realTime == false)
    }

    @Test("baseline distance is average human IPD")
    func baselineDistanceIPD() {
        #expect(MVHEVCEncoderConfiguration().baselineDistance == 63.5)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = MVHEVCEncoderConfiguration.spatialVideo
        let b = MVHEVCEncoderConfiguration.spatialVideo
        #expect(a == b)
    }

    @Test("different configs not equal")
    func notEqual() {
        #expect(
            MVHEVCEncoderConfiguration.spatialVideo
                != MVHEVCEncoderConfiguration.spatialVideoHQ
        )
    }
}
