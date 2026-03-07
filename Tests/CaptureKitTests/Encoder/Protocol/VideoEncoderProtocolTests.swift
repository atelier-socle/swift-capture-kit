// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("VideoEncoderProtocol")
struct VideoEncoderProtocolTests {

    @Test("MockVideoEncoder conforms to VideoEncoderProtocol")
    func mockConformsToProtocol() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let encoder = MockVideoEncoder()
        #expect(encoder.codec == .h264)
        #expect(encoder.supportedResolutions == [.p720, .p1080])
        #expect(encoder.supportedFrameRates == [.fps30, .fps60])
        #expect(encoder.supportedBitRates == 500_000...10_000_000)
        #expect(encoder.supportedProfiles == ["baseline", "main", "high"])
        #expect(encoder.isHardwareAccelerated == false)

        let config = VideoEncoderConfiguration(
            bitrate: 5_000_000,
            resolution: .p1080,
            frameRate: .fps30,
            keyFrameInterval: 60,
            realTime: true
        )
        try await encoder.configure(config)
        let configCount = await encoder.configureCallCount
        #expect(configCount == 1)

        let format = VideoFormat(resolution: .p1080, frameRate: .fps30)
        let frame = VideoFrame(
            data: Data([0x01]),
            format: format,
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 1
        )
        let encoded = try await encoder.encode(frame)
        #expect(encoded.codec == .h264)
        let encodeCount = await encoder.encodeCallCount
        #expect(encodeCount == 1)

        try await encoder.forceKeyFrame()
        let forceCount = await encoder.forceKeyFrameCallCount
        #expect(forceCount == 1)

        try await encoder.updateBitrate(3_000_000)
        let updateCount = await encoder.updateBitrateCallCount
        #expect(updateCount == 1)

        let flushed = try await encoder.flush()
        #expect(flushed.isEmpty)

        await encoder.reset()
        let resetCount = await encoder.resetCallCount
        #expect(resetCount == 1)
    }

    @Test("VideoEncoderConfiguration init stores properties")
    func configurationInit() {
        let config = VideoEncoderConfiguration(
            bitrate: 8_000_000,
            resolution: .uhd4K,
            frameRate: .fps60,
            keyFrameInterval: 120,
            realTime: false
        )
        #expect(config.bitrate == 8_000_000)
        #expect(config.resolution == .uhd4K)
        #expect(config.frameRate == .fps60)
        #expect(config.keyFrameInterval == 120)
        #expect(config.realTime == false)
    }

    @Test("VideoEncoderConfiguration Equatable")
    func configurationEquatable() {
        let a = VideoEncoderConfiguration(
            bitrate: 5_000_000, resolution: .p1080,
            frameRate: .fps30, keyFrameInterval: 60, realTime: true
        )
        let b = VideoEncoderConfiguration(
            bitrate: 5_000_000, resolution: .p1080,
            frameRate: .fps30, keyFrameInterval: 60, realTime: true
        )
        let c = VideoEncoderConfiguration(
            bitrate: 3_000_000, resolution: .p720,
            frameRate: .fps30, keyFrameInterval: 60, realTime: true
        )
        #expect(a == b)
        #expect(a != c)
    }
}
