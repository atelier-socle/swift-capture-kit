// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ProResEncoderConfiguration", .timeLimit(.minutes(1)))
struct ProResEncoderConfigurationTests {
    @Test("default values")
    func defaultValues() {
        let config = ProResEncoderConfiguration()
        #expect(config.profile == .hq)
        #expect(config.realTime == true)
    }

    @Test("proxy preset")
    func proxyPreset() {
        #expect(ProResEncoderConfiguration.proxy.profile == .proxy)
    }

    @Test("p4444xq preset is not realTime")
    func p4444xqNotRealTime() {
        #expect(ProResEncoderConfiguration.p4444xq.realTime == false)
    }

    @Test("all presets exist")
    func allPresetsExist() {
        _ = ProResEncoderConfiguration.proxy
        _ = ProResEncoderConfiguration.lt
        _ = ProResEncoderConfiguration.standard
        _ = ProResEncoderConfiguration.hq
        _ = ProResEncoderConfiguration.p4444
        _ = ProResEncoderConfiguration.p4444xq
    }

    @Test("Equatable conformance")
    func equatable() {
        #expect(
            ProResEncoderConfiguration.hq
                == ProResEncoderConfiguration()
        )
    }

    @Test("different presets not equal")
    func notEqual() {
        #expect(
            ProResEncoderConfiguration.proxy
                != ProResEncoderConfiguration.hq
        )
    }
}
