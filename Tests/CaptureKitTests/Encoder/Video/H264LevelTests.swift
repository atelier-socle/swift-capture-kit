// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("H264Level")
struct H264LevelTests {
    @Test("all cases are available")
    func allCases() {
        #expect(H264Level.allCases.count == 10)
    }

    @Test("auto level exists")
    func autoLevel() {
        #expect(H264Level.auto.rawValue == "auto")
    }

    @Test("level51 raw value")
    func level51RawValue() {
        #expect(H264Level.level51.rawValue == "level51")
    }

    @Test("is Sendable")
    func isSendable() {
        let level: any Sendable = H264Level.auto
        #expect(level is H264Level)
    }
}
