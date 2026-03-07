// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ProResEncoder")
struct ProResEncoderTests {

    private func makeEncoder() -> ProResEncoder {
        ProResEncoder()
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

    @Test("codec is prores")
    func codecIsProres() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .prores)
    }

    @Test("is hardware accelerated")
    func isHardwareAccelerated() {
        let encoder = makeEncoder()
        #expect(encoder.isHardwareAccelerated == true)
    }

    @Test("supported bit rates is 0 (profile-determined)")
    func supportedBitRatesIsZero() {
        let encoder = makeEncoder()
        #expect(encoder.supportedBitRates == 0...0)
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
        try await encoder.configure(prores: .hq)
        let configured = await encoder.isConfigured
        #expect(configured == true)
    }

    @Test("encode always produces keyframe")
    func encodeAlwaysProducesKeyframe() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(prores: .hq)
        let frame = makeFrame(isKeyFrame: false)
        let encoded = try await encoder.encode(frame)
        #expect(encoded.isKeyFrame == true)
    }

    @Test("updateBitrate is a no-op")
    func updateBitrateIsNoOp() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(prores: .hq)
        try await encoder.updateBitrate(10_000_000)
    }

    @Test("forceKeyFrame is a no-op")
    func forceKeyFrameIsNoOp() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.forceKeyFrame()
    }
}
