// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ProResProfile", .timeLimit(.minutes(1)))
struct ProResProfileTests {
    @Test("all 6 profiles exist")
    func allCases() {
        #expect(ProResProfile.allCases.count == 6)
    }

    @Test("proxy has lowest bitrate")
    func proxyLowestBitrate() {
        let min = ProResProfile.allCases.map(
            \.approximateBitrateMbps1080p
        ).min()
        #expect(min == ProResProfile.proxy.approximateBitrateMbps1080p)
    }

    @Test("p4444xq has highest bitrate")
    func p4444xqHighestBitrate() {
        let max = ProResProfile.allCases.map(
            \.approximateBitrateMbps1080p
        ).max()
        #expect(max == ProResProfile.p4444xq.approximateBitrateMbps1080p)
    }

    @Test("p4444 supports alpha")
    func p4444SupportsAlpha() {
        #expect(ProResProfile.p4444.supportsAlpha == true)
    }

    @Test("p4444xq supports alpha")
    func p4444xqSupportsAlpha() {
        #expect(ProResProfile.p4444xq.supportsAlpha == true)
    }

    @Test("proxy does not support alpha")
    func proxyNoAlpha() {
        #expect(ProResProfile.proxy.supportsAlpha == false)
    }

    @Test("proxy is 422")
    func proxyIs422() {
        #expect(ProResProfile.proxy.is422 == true)
    }

    @Test("p4444 is not 422")
    func p4444NotIs422() {
        #expect(ProResProfile.p4444.is422 == false)
    }
}
