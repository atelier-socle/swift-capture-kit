// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("FrameRate")
struct FrameRateTests {

    @Test("value correctness for all named cases")
    func valueCorrectnessForNamedCases() {
        #expect(FrameRate.fps1.value == 1)
        #expect(FrameRate.fps15.value == 15)
        #expect(FrameRate.fps24.value == 24)
        #expect(FrameRate.fps25.value == 25)
        #expect(FrameRate.fps30.value == 30)
        #expect(FrameRate.fps48.value == 48)
        #expect(FrameRate.fps50.value == 50)
        #expect(FrameRate.fps60.value == 60)
        #expect(FrameRate.fps90.value == 90)
        #expect(FrameRate.fps100.value == 100)
        #expect(FrameRate.fps120.value == 120)
        #expect(FrameRate.fps240.value == 240)
    }

    @Test("fps23_976 value is 23.976")
    func fps23_976Value() {
        #expect(FrameRate.fps23_976.value == 23.976)
    }

    @Test("fps29_97 value is 29.97")
    func fps29_97Value() {
        #expect(FrameRate.fps29_97.value == 29.97)
    }

    @Test("fps59_94 value is 59.94")
    func fps59_94Value() {
        #expect(FrameRate.fps59_94.value == 59.94)
    }

    @Test("custom frame rate returns the provided value")
    func customValue() {
        let custom = FrameRate.custom(75.0)
        #expect(custom.value == 75.0)
    }

    @Test("Equatable: same cases are equal")
    func equatableSameCases() {
        #expect(FrameRate.fps30 == FrameRate.fps30)
    }

    @Test("Equatable: different cases are not equal")
    func equatableDifferentCases() {
        #expect(FrameRate.fps30 != FrameRate.fps60)
    }

    @Test("Equatable: custom cases with same value are equal")
    func equatableCustomSameValue() {
        #expect(FrameRate.custom(45.0) == FrameRate.custom(45.0))
    }
}
