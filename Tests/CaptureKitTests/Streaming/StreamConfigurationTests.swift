// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("StreamConfiguration", .timeLimit(.minutes(1)))
struct StreamConfigurationTests {

    @Test("video configuration stores codec and parameter sets")
    func videoConfiguration() {
        let sps = Data([0x67, 0x42, 0x00, 0x1E])
        let pps = Data([0x68, 0xCE, 0x38, 0x80])
        let parameterSets = sps + pps
        let config = StreamConfiguration.video(
            codec: .h264, parameterSets: parameterSets)
        if case .video(let codec, let data) = config {
            #expect(codec == .h264)
            #expect(data == parameterSets)
        } else {
            Issue.record("Expected .video case")
        }
    }

    @Test("audio configuration stores codec and config data")
    func audioConfiguration() {
        let asc = Data([0x12, 0x10])
        let config = StreamConfiguration.audio(
            codec: .aac, configData: asc)
        if case .audio(let codec, let data) = config {
            #expect(codec == .aac)
            #expect(data == asc)
        } else {
            Issue.record("Expected .audio case")
        }
    }

    @Test("hevc video configuration")
    func hevcVideoConfiguration() {
        let vps = Data([0x40, 0x01])
        let sps = Data([0x42, 0x01])
        let pps = Data([0x44, 0x01])
        let parameterSets = vps + sps + pps
        let config = StreamConfiguration.video(
            codec: .hevc, parameterSets: parameterSets)
        if case .video(let codec, let data) = config {
            #expect(codec == .hevc)
            #expect(data.count == 6)
        } else {
            Issue.record("Expected .video case")
        }
    }

    @Test("opus audio configuration")
    func opusAudioConfiguration() {
        let opusHead = Data([0x4F, 0x70, 0x75, 0x73])
        let config = StreamConfiguration.audio(
            codec: .opus, configData: opusHead)
        if case .audio(let codec, let data) = config {
            #expect(codec == .opus)
            #expect(data == opusHead)
        } else {
            Issue.record("Expected .audio case")
        }
    }
}
