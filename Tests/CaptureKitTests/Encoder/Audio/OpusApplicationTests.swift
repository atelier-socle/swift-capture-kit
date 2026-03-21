// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("OpusApplication", .timeLimit(.minutes(1)))
struct OpusApplicationTests {
    @Test("all cases are available")
    func allCasesAvailable() {
        #expect(OpusApplication.allCases.count == 3)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(OpusApplication.audio.rawValue == "audio")
        #expect(OpusApplication.voip.rawValue == "voip")
        #expect(OpusApplication.restrictedLowDelay.rawValue == "restrictedLowDelay")
    }

    @Test("is Sendable")
    func isSendable() {
        let app: any Sendable = OpusApplication.audio
        #expect(app is OpusApplication)
    }
}
