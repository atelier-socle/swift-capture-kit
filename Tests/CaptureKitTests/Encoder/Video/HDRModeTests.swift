// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("HDRMode")
struct HDRModeTests {
    @Test("all cases are available")
    func allCases() {
        #expect(HDRMode.allCases.count == 4)
    }

    @Test("SDR requires main profile")
    func sdrRequiresMain() {
        #expect(HDRMode.sdr.requiredProfile == .main)
    }

    @Test("HDR10 requires main10 profile")
    func hdr10RequiresMain10() {
        #expect(HDRMode.hdr10.requiredProfile == .main10)
    }

    @Test("HLG requires main10 profile")
    func hlgRequiresMain10() {
        #expect(HDRMode.hlg.requiredProfile == .main10)
    }

    @Test("Dolby Vision requires main10 profile")
    func dolbyVisionRequiresMain10() {
        #expect(HDRMode.dolbyVision.requiredProfile == .main10)
    }
}
