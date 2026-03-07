// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("H264Encoder")
struct H264EncoderTests {

    private func makeEncoder() -> H264Encoder {
        H264Encoder()
    }

    private func makeFrame(isKeyFrame: Bool = true) -> VideoFrame {
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
            isKeyFrame: isKeyFrame,
            sequenceNumber: 1
        )
    }

    @Test("codec is h264")
    func codecIsH264() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .h264)
    }

    @Test("is hardware accelerated")
    func isHardwareAccelerated() {
        let encoder = makeEncoder()
        #expect(encoder.isHardwareAccelerated == true)
    }

    @Test("supported resolutions include 1080p")
    func supportedResolutionsInclude1080p() {
        let encoder = makeEncoder()
        #expect(encoder.supportedResolutions.contains(.p1080))
    }

    @Test("supported frame rates include 30fps")
    func supportedFrameRatesInclude30fps() {
        let encoder = makeEncoder()
        #expect(encoder.supportedFrameRates.contains(.fps30))
    }

    @Test("supported bit rates upper bound")
    func supportedBitRatesUpperBound() {
        let encoder = makeEncoder()
        #expect(encoder.supportedBitRates.contains(100_000_000))
    }

    @Test("not configured initially")
    func notConfiguredInitially() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let configured = await encoder.isConfigured
        #expect(configured == false)
    }

    @Test("configure sets isConfigured")
    func configureSetsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(h264: .streaming1080p)
        let configured = await encoder.isConfigured
        #expect(configured == true)
    }

    @Test("configure with invalid config throws")
    func configureWithInvalidConfigThrows() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let invalidConfig = H264EncoderConfiguration(
            profile: .baseline,
            bFrames: true,
            entropyMode: .cavlc
        )
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(h264: invalidConfig)
        }
    }

    @Test("encode before configure throws")
    func encodeBeforeConfigureThrows() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            try await encoder.encode(frame)
        }
    }

    @Test("encode returns frame with h264 codec")
    func encodeReturnsFrameWithH264Codec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(h264: .streaming1080p)
        let frame = makeFrame()
        let encoded = try await encoder.encode(frame)
        #expect(encoded.codec == .h264)
        #expect(encoded.isKeyFrame == true)
        #expect(encoded.sequenceNumber == 1)
    }
}
