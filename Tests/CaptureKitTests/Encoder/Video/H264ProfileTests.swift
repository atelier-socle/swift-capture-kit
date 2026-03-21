// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("H264Profile", .timeLimit(.minutes(1)))
struct H264ProfileTests {
    @Test("all cases are available")
    func allCases() {
        #expect(H264Profile.allCases.count == 4)
    }

    @Test("baseline does not support B-frames")
    func baselineNoBFrames() {
        #expect(H264Profile.baseline.supportsBFrames == false)
    }

    @Test("main supports B-frames")
    func mainSupportsBFrames() {
        #expect(H264Profile.main.supportsBFrames == true)
    }

    @Test("baseline does not support CABAC")
    func baselineNoCabac() {
        #expect(H264Profile.baseline.supportsCabac == false)
    }

    @Test("high supports CABAC")
    func highSupportsCabac() {
        #expect(H264Profile.high.supportsCabac == true)
    }

    @Test("high10 has max bit depth 10")
    func high10BitDepth() {
        #expect(H264Profile.high10.maxBitDepth == 10)
        #expect(H264Profile.high.maxBitDepth == 8)
    }
}
