// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("HEVCEncoderConfiguration", .timeLimit(.minutes(1)))
struct HEVCEncoderConfigurationTests {
    @Test("default values")
    func defaultValues() {
        let config = HEVCEncoderConfiguration()
        #expect(config.profile == .main)
        #expect(config.bitrate == 5_000_000)
        #expect(config.hdrMode == .sdr)
        #expect(config.alphaChannel == false)
    }

    @Test("streaming1080p preset values")
    func streaming1080p() {
        let config = HEVCEncoderConfiguration.streaming1080p
        #expect(config.profile == .main)
        #expect(config.bitrate == 5_000_000)
    }

    @Test("hdr4K preset uses main10 profile")
    func hdr4K() {
        let config = HEVCEncoderConfiguration.hdr4K
        #expect(config.profile == .main10)
        #expect(config.hdrMode == .hdr10)
        #expect(config.bitrate == 25_000_000)
    }

    @Test("hlgBroadcast preset values")
    func hlgBroadcast() {
        let config = HEVCEncoderConfiguration.hlgBroadcast
        #expect(config.profile == .main10)
        #expect(config.hdrMode == .hlg)
    }

    @Test("screenRecording preset has no bFrames")
    func screenRecording() {
        let config = HEVCEncoderConfiguration.screenRecording
        #expect(config.bFrames == false)
    }

    @Test("validate succeeds for SDR with main profile")
    func validateSucceedsSDR() throws {
        try HEVCEncoderConfiguration.streaming1080p.validate()
    }

    @Test("validate throws for HDR10 with main profile")
    func validateThrowsHDR10Main() {
        let config = HEVCEncoderConfiguration(
            profile: .main, hdrMode: .hdr10
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for dolbyVision with main profile")
    func validateThrowsDolbyMain() {
        let config = HEVCEncoderConfiguration(
            profile: .main, hdrMode: .dolbyVision
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate succeeds for HDR10 with main10 profile")
    func validateSucceedsHDR10Main10() throws {
        try HEVCEncoderConfiguration.hdr4K.validate()
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = HEVCEncoderConfiguration.streaming1080p
        let b = HEVCEncoderConfiguration.streaming1080p
        #expect(a == b)
    }
}
