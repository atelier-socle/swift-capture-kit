// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PCMByteOrder", .timeLimit(.minutes(1)))
struct PCMByteOrderTests {
    @Test("all cases are available")
    func allCasesAvailable() {
        #expect(PCMByteOrder.allCases.count == 3)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(PCMByteOrder.native.rawValue == "native")
        #expect(PCMByteOrder.bigEndian.rawValue == "bigEndian")
        #expect(PCMByteOrder.littleEndian.rawValue == "littleEndian")
    }

    @Test("is Sendable")
    func isSendable() {
        let order: any Sendable = PCMByteOrder.native
        #expect(order is PCMByteOrder)
    }
}
