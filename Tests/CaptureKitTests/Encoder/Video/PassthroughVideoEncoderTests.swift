// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PassthroughVideoEncoder")
struct PassthroughVideoEncoderTests {

    @Test("configure does not throw")
    func configureDoesNotThrow() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughVideoEncoder()
        try await encoder.configure(
            width: 1920,
            height: 1080,
            codec: .h264,
            bitrate: 5_000_000,
            frameRate: 30.0,
            keyFrameInterval: 60,
            realTime: true,
            profileLevel: nil
        )
    }

    @Test("encode returns data unchanged from input frame")
    func encodeReturnsDataUnchanged() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughVideoEncoder()
        let inputData = Data([0x00, 0x01, 0x02, 0x03, 0x04])
        let result = try await encoder.encode(
            data: inputData,
            width: 320,
            height: 240,
            timestamp: 0.0,
            isKeyFrame: true
        )
        #expect(result == inputData)
    }

    @Test("forceKeyFrame does not throw")
    func forceKeyFrameDoesNotThrow() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughVideoEncoder()
        try await encoder.forceKeyFrame()
    }

    @Test("updateBitrate does not throw")
    func updateBitrateDoesNotThrow() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughVideoEncoder()
        try await encoder.updateBitrate(10_000_000)
    }

    @Test("reset does not throw")
    func resetDoesNotThrow() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughVideoEncoder()
        await encoder.reset()
    }

    @Test("encode preserves exact byte content and length")
    func encodePreservesFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughVideoEncoder()
        let frameBytes: [UInt8] = Array(0..<200)
        let inputData = Data(frameBytes)
        let result = try await encoder.encode(
            data: inputData,
            width: 640,
            height: 480,
            timestamp: 1.5,
            isKeyFrame: false
        )
        #expect(result.count == inputData.count)
        #expect(result == inputData)
    }

    @Test("flush returns nil")
    func flushReturnsNil() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughVideoEncoder()
        let result = try await encoder.flush()
        #expect(result == nil)
    }

    @Test("multiple sequential encodes return correct data each time")
    func multipleEncodesWork() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughVideoEncoder()
        let first = Data([0xAA, 0xBB])
        let second = Data([0xCC, 0xDD, 0xEE])

        let result1 = try await encoder.encode(
            data: first, width: 320, height: 240, timestamp: 0.0, isKeyFrame: true
        )
        let result2 = try await encoder.encode(
            data: second, width: 320, height: 240, timestamp: 0.033, isKeyFrame: false
        )

        #expect(result1 == first)
        #expect(result2 == second)
    }
}
