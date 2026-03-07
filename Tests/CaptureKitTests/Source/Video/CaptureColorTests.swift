// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CaptureColor")
struct CaptureColorTests {

    @Test("init stores components correctly")
    func initStoresComponents() {
        let color = CaptureColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.8)
        #expect(color.red == 0.2)
        #expect(color.green == 0.4)
        #expect(color.blue == 0.6)
        #expect(color.alpha == 0.8)
    }

    @Test("default alpha is 1.0")
    func defaultAlpha() {
        let color = CaptureColor(red: 0.5, green: 0.5, blue: 0.5)
        #expect(color.alpha == 1.0)
    }

    @Test("static black has all zeros")
    func staticBlack() {
        #expect(CaptureColor.black.red == 0)
        #expect(CaptureColor.black.green == 0)
        #expect(CaptureColor.black.blue == 0)
        #expect(CaptureColor.black.alpha == 1.0)
    }

    @Test("static white has all ones")
    func staticWhite() {
        #expect(CaptureColor.white.red == 1)
        #expect(CaptureColor.white.green == 1)
        #expect(CaptureColor.white.blue == 1)
        #expect(CaptureColor.white.alpha == 1.0)
    }

    @Test("static red, green, blue are correct")
    func staticPrimaryColors() {
        #expect(CaptureColor.red == CaptureColor(red: 1, green: 0, blue: 0))
        #expect(CaptureColor.green == CaptureColor(red: 0, green: 1, blue: 0))
        #expect(CaptureColor.blue == CaptureColor(red: 0, green: 0, blue: 1))
    }

    @Test("Equatable same values are equal")
    func equatableSameValues() {
        let color1 = CaptureColor(red: 0.3, green: 0.6, blue: 0.9)
        let color2 = CaptureColor(red: 0.3, green: 0.6, blue: 0.9)
        #expect(color1 == color2)
    }

    @Test("Equatable different values are not equal")
    func equatableDifferentValues() {
        let color1 = CaptureColor(red: 0.1, green: 0.2, blue: 0.3)
        let color2 = CaptureColor(red: 0.4, green: 0.5, blue: 0.6)
        #expect(color1 != color2)
    }

    @Test("Hashable allows use in Set")
    func hashableInSet() {
        let color1 = CaptureColor(red: 1, green: 0, blue: 0)
        let color2 = CaptureColor(red: 0, green: 1, blue: 0)
        let color3 = CaptureColor(red: 1, green: 0, blue: 0)

        let set: Set<CaptureColor> = [color1, color2, color3]
        #expect(set.count == 2)
    }
}
