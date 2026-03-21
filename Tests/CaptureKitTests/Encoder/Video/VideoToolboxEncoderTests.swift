// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("VideoToolboxEncoder via MockVideoEncoderProvider", .timeLimit(.minutes(1)))
struct VideoToolboxEncoderTests {

    @Test("configure calls provider configure")
    func configureCallsProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        let count = await provider.configureCallCount
        #expect(count == 1)
    }

    @Test("configure passes codec to provider")
    func configurePassesCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        let codec = await provider.lastCodec
        #expect(codec == .h264)
    }

    @Test("encode calls provider encode")
    func encodeCallsProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        let frame = makeFrame()
        _ = try await encoder.encode(frame)
        let count = await provider.encodeCallCount
        #expect(count == 1)
    }

    @Test("encode before configure throws")
    func encodeBeforeConfigureThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            _ = try await encoder.encode(frame)
        }
    }

    @Test("forceKeyFrame calls provider")
    func forceKeyFrameCallsProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.forceKeyFrame()
        let count = await provider.forceKeyFrameCallCount
        #expect(count == 1)
    }

    @Test("updateBitrate calls provider")
    func updateBitrateCallsProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        try await encoder.updateBitrate(5_000_000)
        let count = await provider.updateBitrateCallCount
        #expect(count == 1)
        let bitrate = await provider.lastBitrate
        #expect(bitrate == 5_000_000)
    }

    @Test("reset calls provider reset")
    func resetCallsProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        await encoder.reset()
        let count = await provider.resetCallCount
        #expect(count == 1)
    }

    @Test("provider configure error propagates")
    func providerConfigureErrorPropagates() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        await provider.setThrowOnConfigure(true)
        let encoder = H264Encoder(encoderProvider: provider)
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(h264: .streaming1080p)
        }
    }

    @Test("provider encode error propagates")
    func providerEncodeErrorPropagates() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        await provider.setThrowOnEncode(true)
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            _ = try await encoder.encode(frame)
        }
    }

    @Test("HEVC configure passes hevc codec")
    func hevcConfigurePassesCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = HEVCEncoder(encoderProvider: provider)
        try await encoder.configure(hevc: .streaming1080p)
        let codec = await provider.lastCodec
        #expect(codec == .hevc)
    }

    @Test("ProRes configure passes prores codec")
    func proresConfigurePassesCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = ProResEncoder(encoderProvider: provider)
        try await encoder.configure(prores: .hq)
        let codec = await provider.lastCodec
        #expect(codec == .prores)
    }

    @Test("AV1 configure passes av1 codec")
    func av1ConfigurePassesCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = AV1Encoder(encoderProvider: provider)
        try await encoder.configure(av1: .streaming1080p)
        let codec = await provider.lastCodec
        #expect(codec == .av1)
    }

    // MARK: - Helpers

    private func makeFrame() -> VideoFrame {
        let format = VideoFormat(
            resolution: .p1080,
            frameRate: .fps30,
            pixelFormat: .bgra,
            colorSpace: .bt709,
            dynamicRange: .sdr,
            bitDepth: .bit8
        )
        return VideoFrame(
            data: Data(repeating: 0, count: 1024),
            format: format,
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 1
        )
    }
}

// MARK: - MockVideoEncoderProvider helpers

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension MockVideoEncoderProvider {
    func setThrowOnConfigure(_ value: Bool) {
        self.shouldThrowOnConfigure = value
    }

    func setThrowOnEncode(_ value: Bool) {
        self.shouldThrowOnEncode = value
    }
}
