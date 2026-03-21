// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AudioBitrateMode", .timeLimit(.minutes(1)))
struct AudioBitrateModeTests {
    @Test("all cases are available")
    func allCasesAvailable() {
        #expect(AudioBitrateMode.allCases.count == 3)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(AudioBitrateMode.constant.rawValue == "constant")
        #expect(AudioBitrateMode.variable.rawValue == "variable")
        #expect(AudioBitrateMode.constrained.rawValue == "constrained")
    }

    @Test("is Sendable")
    func isSendable() {
        let mode: any Sendable = AudioBitrateMode.constant
        #expect(mode is AudioBitrateMode)
    }
}
