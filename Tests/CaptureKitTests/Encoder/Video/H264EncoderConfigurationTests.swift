// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("H264EncoderConfiguration")
struct H264EncoderConfigurationTests {
    @Test("default values")
    func defaultValues() {
        let config = H264EncoderConfiguration()
        #expect(config.profile == .high)
        #expect(config.level == .auto)
        #expect(config.bitrate == 5_000_000)
        #expect(config.bitrateMode == .average)
        #expect(config.keyFrameInterval == 60)
        #expect(config.bFrames == true)
        #expect(config.entropyMode == .cabac)
        #expect(config.realTime == true)
        #expect(config.maxSliceBytes == nil)
    }

    @Test("streaming720p preset values")
    func streaming720p() {
        let config = H264EncoderConfiguration.streaming720p
        #expect(config.profile == .main)
        #expect(config.level == .level31)
        #expect(config.bitrate == 2_500_000)
    }

    @Test("streaming1080p preset values")
    func streaming1080p() {
        let config = H264EncoderConfiguration.streaming1080p
        #expect(config.profile == .high)
        #expect(config.bitrate == 4_500_000)
    }

    @Test("lowLatency preset uses baseline profile")
    func lowLatencyPreset() {
        let config = H264EncoderConfiguration.lowLatency
        #expect(config.profile == .baseline)
        #expect(config.bFrames == false)
        #expect(config.entropyMode == .cavlc)
    }

    @Test("archive preset uses high bitrate")
    func archivePreset() {
        let config = H264EncoderConfiguration.archive
        #expect(config.bitrate == 20_000_000)
        #expect(config.realTime == false)
    }

    @Test("validate succeeds for valid config")
    func validateSucceeds() throws {
        try H264EncoderConfiguration.streaming1080p.validate()
    }

    @Test("validate throws for baseline with bFrames")
    func validateBaselineBFrames() {
        let config = H264EncoderConfiguration(
            profile: .baseline, bFrames: true, entropyMode: .cavlc
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for baseline with CABAC")
    func validateBaselineCabac() {
        let config = H264EncoderConfiguration(
            profile: .baseline, bFrames: false, entropyMode: .cabac
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for zero bitrate")
    func validateZeroBitrate() {
        let config = H264EncoderConfiguration(bitrate: 0)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("validate throws for zero keyFrameInterval")
    func validateZeroKeyFrameInterval() {
        let config = H264EncoderConfiguration(keyFrameInterval: 0)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = H264EncoderConfiguration.streaming1080p
        let b = H264EncoderConfiguration.streaming1080p
        #expect(a == b)
        #expect(a != H264EncoderConfiguration.lowLatency)
    }

    @Test("maxSliceBytes is optional and nil by default")
    func maxSliceBytesDefault() {
        #expect(H264EncoderConfiguration().maxSliceBytes == nil)
    }
}
