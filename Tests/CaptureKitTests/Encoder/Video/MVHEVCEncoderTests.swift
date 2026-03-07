// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("MVHEVCEncoder")
struct MVHEVCEncoderTests {

    private func makeEncoder() -> MVHEVCEncoder {
        MVHEVCEncoder(encoderProvider: MockVideoEncoderProvider())
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

    @Test("codec is mvHevc")
    func codecIsMvHevc() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .mvHevc)
    }

    @Test("supported profiles contains stereo")
    func supportedProfilesContainsStereo() {
        let encoder = makeEncoder()
        #expect(encoder.supportedProfiles.contains("stereo"))
    }

    @Test("supported frame rates is fps30 only")
    func supportedFrameRatesIsFps30Only() {
        let encoder = makeEncoder()
        #expect(encoder.supportedFrameRates == [.fps30])
    }

    @Test("supported bit rates range")
    func supportedBitRatesRange() {
        let encoder = makeEncoder()
        #expect(encoder.supportedBitRates == 10_000_000...50_000_000)
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
        try await encoder.configure(mvhevc: .spatialVideo)
        let configured = await encoder.isConfigured
        #expect(configured == true)
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

    @Test("encode returns frame with mvHevc codec")
    func encodeReturnsFrameWithMvHevcCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(mvhevc: .spatialVideo)
        let frame = makeFrame()
        let encoded = try await encoder.encode(frame)
        #expect(encoded.codec == .mvHevc)
        #expect(encoded.isKeyFrame == true)
        #expect(encoded.sequenceNumber == 1)
    }
}
