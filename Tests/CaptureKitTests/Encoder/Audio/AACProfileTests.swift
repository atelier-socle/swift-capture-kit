// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AACProfile", .timeLimit(.minutes(1)))
struct AACProfileTests {
    @Test("all cases are available")
    func allCasesAvailable() {
        #expect(AACProfile.allCases.count == 5)
    }

    @Test("LC bitrate range is 32k-320k")
    func lcBitrateRange() {
        #expect(AACProfile.lc.bitrateRange == 32_000...320_000)
    }

    @Test("HE v1 bitrate range is 16k-128k")
    func heV1BitrateRange() {
        #expect(AACProfile.heV1.bitrateRange == 16_000...128_000)
    }

    @Test("HE v2 bitrate range is 12k-64k")
    func heV2BitrateRange() {
        #expect(AACProfile.heV2.bitrateRange == 12_000...64_000)
    }

    @Test("ELD bitrate range is 16k-128k")
    func eldBitrateRange() {
        #expect(AACProfile.eld.bitrateRange == 16_000...128_000)
    }

    @Test("xHE bitrate range is 8k-256k")
    func xheBitrateRange() {
        #expect(AACProfile.xHE.bitrateRange == 8_000...256_000)
    }

    @Test("HE v2 max channels is 2")
    func heV2MaxChannels() {
        #expect(AACProfile.heV2.maxChannels == 2)
    }

    @Test("only ELD supports low latency")
    func onlyELDSupportsLowLatency() {
        #expect(AACProfile.eld.supportsLowLatency == true)
        #expect(AACProfile.lc.supportsLowLatency == false)
        #expect(AACProfile.heV1.supportsLowLatency == false)
        #expect(AACProfile.heV2.supportsLowLatency == false)
        #expect(AACProfile.xHE.supportsLowLatency == false)
    }
}
