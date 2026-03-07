// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AV1Encoder")
struct AV1EncoderTests {

    private func makeEncoder() -> AV1Encoder {
        AV1Encoder()
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

    @Test("codec is av1")
    func codecIsAv1() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .av1)
    }

    @Test("supported resolutions include 4K")
    func supportedResolutionsInclude4K() {
        let encoder = makeEncoder()
        #expect(encoder.supportedResolutions.contains(.uhd4K))
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
        try await encoder.configure(av1: .streaming1080p)
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

    @Test("encode returns frame with av1 codec")
    func encodeReturnsFrameWithAv1Codec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(av1: .streaming1080p)
        let frame = makeFrame()
        let encoded = try await encoder.encode(frame)
        #expect(encoded.codec == .av1)
        #expect(encoded.isKeyFrame == true)
        #expect(encoded.sequenceNumber == 1)
    }

    @Test("updateBitrate updates configuration")
    func updateBitrateUpdatesConfiguration() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(av1: .streaming1080p)
        try await encoder.updateBitrate(10_000_000)
        let config = await encoder.configuration
        #expect(config.bitrate == 10_000_000)
    }

    @Test("reset clears isConfigured")
    func resetClearsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(av1: .streaming1080p)
        let configuredBefore = await encoder.isConfigured
        #expect(configuredBefore == true)
        await encoder.reset()
        let configuredAfter = await encoder.isConfigured
        #expect(configuredAfter == false)
    }

    @Test("forceKeyFrame does not throw")
    func forceKeyFrameDoesNotThrow() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.forceKeyFrame()
    }
}
