// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("ContinuityCameraFeatures")
struct ContinuityCameraFeaturesTests {

    @Test("default init has all false")
    func defaultInitAllFalse() {
        let features = ContinuityCameraFeatures()
        #expect(features.centerStage == false)
        #expect(features.deskView == false)
        #expect(features.portraitMode == false)
        #expect(features.studioLight == false)
    }

    @Test("init with custom values stores correctly")
    func initWithCustomValues() {
        let features = ContinuityCameraFeatures(
            centerStage: true,
            deskView: true,
            portraitMode: false,
            studioLight: true
        )
        #expect(features.centerStage == true)
        #expect(features.deskView == true)
        #expect(features.portraitMode == false)
        #expect(features.studioLight == true)
    }

    @Test("allEnabled has centerStage, portraitMode, studioLight true but deskView false")
    func allEnabledValues() {
        let features = ContinuityCameraFeatures.allEnabled
        #expect(features.centerStage == true)
        #expect(features.deskView == false)
        #expect(features.portraitMode == true)
        #expect(features.studioLight == true)
    }

    @Test("Equatable works for same and different values")
    func equatable() {
        let features1 = ContinuityCameraFeatures(centerStage: true)
        let features2 = ContinuityCameraFeatures(centerStage: true)
        let features3 = ContinuityCameraFeatures(centerStage: false)
        #expect(features1 == features2)
        #expect(features1 != features3)
    }

    @Test("properties are mutable")
    func propertiesAreMutable() {
        var features = ContinuityCameraFeatures()
        features.centerStage = true
        features.deskView = true
        features.portraitMode = true
        features.studioLight = true
        #expect(features.centerStage == true)
        #expect(features.deskView == true)
        #expect(features.portraitMode == true)
        #expect(features.studioLight == true)
    }
}
