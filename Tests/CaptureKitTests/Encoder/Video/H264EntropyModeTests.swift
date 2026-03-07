// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("H264EntropyMode")
struct H264EntropyModeTests {
    @Test("all cases are available")
    func allCases() {
        #expect(H264EntropyMode.allCases.count == 2)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(H264EntropyMode.cavlc.rawValue == "cavlc")
        #expect(H264EntropyMode.cabac.rawValue == "cabac")
    }

    @Test("is Sendable")
    func isSendable() {
        let mode: any Sendable = H264EntropyMode.cabac
        #expect(mode is H264EntropyMode)
    }
}
