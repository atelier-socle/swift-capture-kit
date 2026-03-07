// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("HEVCEncoder")
struct HEVCEncoderTests {

    private func makeEncoder() -> HEVCEncoder {
        HEVCEncoder()
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

    @Test("codec is hevc")
    func codecIsHevc() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .hevc)
    }

    @Test("is hardware accelerated")
    func isHardwareAccelerated() {
        let encoder = makeEncoder()
        #expect(encoder.isHardwareAccelerated == true)
    }

    @Test("supported resolutions include 8K")
    func supportedResolutionsInclude8K() {
        let encoder = makeEncoder()
        #expect(encoder.supportedResolutions.contains(.uhd8K))
    }

    @Test("supported frame rates include 120fps")
    func supportedFrameRatesInclude120fps() {
        let encoder = makeEncoder()
        #expect(encoder.supportedFrameRates.contains(.fps120))
    }

    @Test("supported bit rates upper bound")
    func supportedBitRatesUpperBound() {
        let encoder = makeEncoder()
        #expect(encoder.supportedBitRates.contains(200_000_000))
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
        try await encoder.configure(hevc: .streaming1080p)
        let configured = await encoder.isConfigured
        #expect(configured == true)
    }

    @Test("configure with HDR10 and main profile throws")
    func configureWithInvalidHDRConfigThrows() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let invalidConfig = HEVCEncoderConfiguration(
            profile: .main,
            hdrMode: .hdr10
        )
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(hevc: invalidConfig)
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

    @Test("encode returns frame with hevc codec")
    func encodeReturnsFrameWithHevcCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(hevc: .streaming1080p)
        let frame = makeFrame()
        let encoded = try await encoder.encode(frame)
        #expect(encoded.codec == .hevc)
        #expect(encoded.isKeyFrame == true)
        #expect(encoded.sequenceNumber == 1)
    }
}
