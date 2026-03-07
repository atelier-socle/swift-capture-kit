// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockVideoEncoder: VideoEncoderProtocol {
    let codec: VideoCodec
    let supportedResolutions: [VideoResolution]
    let supportedFrameRates: [FrameRate]
    let supportedBitRates: ClosedRange<Int>
    let supportedProfiles: [String]
    let isHardwareAccelerated: Bool

    private(set) var configureCallCount = 0
    private(set) var encodeCallCount = 0
    private(set) var forceKeyFrameCallCount = 0
    private(set) var updateBitrateCallCount = 0
    private(set) var flushCallCount = 0
    private(set) var resetCallCount = 0

    private var _configuration: VideoEncoderConfiguration?
    private var _currentBitrate: Int?

    init(
        codec: VideoCodec = .h264,
        supportedResolutions: [VideoResolution] = [.p720, .p1080],
        supportedFrameRates: [FrameRate] = [.fps30, .fps60],
        supportedBitRates: ClosedRange<Int> = 500_000...10_000_000,
        supportedProfiles: [String] = ["baseline", "main", "high"],
        isHardwareAccelerated: Bool = false
    ) {
        self.codec = codec
        self.supportedResolutions = supportedResolutions
        self.supportedFrameRates = supportedFrameRates
        self.supportedBitRates = supportedBitRates
        self.supportedProfiles = supportedProfiles
        self.isHardwareAccelerated = isHardwareAccelerated
    }

    func configure(_ config: VideoEncoderConfiguration) async throws {
        configureCallCount += 1
        _configuration = config
        _currentBitrate = config.bitrate
    }

    func encode(_ frame: VideoFrame) async throws -> EncodedVideoFrame {
        encodeCallCount += 1
        return EncodedVideoFrame(
            data: frame.data,
            codec: codec,
            timestamp: frame.timestamp,
            isKeyFrame: frame.isKeyFrame,
            sequenceNumber: frame.sequenceNumber
        )
    }

    func forceKeyFrame() async throws {
        forceKeyFrameCallCount += 1
    }

    func updateBitrate(_ bitrate: Int) async throws {
        updateBitrateCallCount += 1
        _currentBitrate = bitrate
    }

    func flush() async throws -> [EncodedVideoFrame] {
        flushCallCount += 1
        return []
    }

    func reset() async {
        resetCallCount += 1
        _configuration = nil
        _currentBitrate = nil
    }
}
