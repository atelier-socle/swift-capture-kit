// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AV1Profile")
struct AV1ProfileTests {
    @Test("all cases are available")
    func allCases() {
        #expect(AV1Profile.allCases.count == 2)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(AV1Profile.main.rawValue == "main")
        #expect(AV1Profile.high.rawValue == "high")
    }

    @Test("is Sendable")
    func isSendable() {
        let profile: any Sendable = AV1Profile.main
        #expect(profile is AV1Profile)
    }
}
