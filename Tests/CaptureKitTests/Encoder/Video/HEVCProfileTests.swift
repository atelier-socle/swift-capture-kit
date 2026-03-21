// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("HEVCProfile", .timeLimit(.minutes(1)))
struct HEVCProfileTests {
    @Test("all cases are available")
    func allCases() {
        #expect(HEVCProfile.allCases.count == 3)
    }

    @Test("main has 8-bit depth")
    func mainBitDepth() {
        #expect(HEVCProfile.main.bitDepth == 8)
    }

    @Test("main10 has 10-bit depth")
    func main10BitDepth() {
        #expect(HEVCProfile.main10.bitDepth == 10)
    }

    @Test("main does not support HDR")
    func mainNoHDR() {
        #expect(HEVCProfile.main.supportsHDR == false)
    }

    @Test("main10 supports HDR")
    func main10SupportsHDR() {
        #expect(HEVCProfile.main10.supportsHDR == true)
    }

    @Test("main42210 has 4:2:2 chroma")
    func main42210Chroma() {
        #expect(HEVCProfile.main42210.chromaSubsampling == "4:2:2")
        #expect(HEVCProfile.main.chromaSubsampling == "4:2:0")
    }
}
