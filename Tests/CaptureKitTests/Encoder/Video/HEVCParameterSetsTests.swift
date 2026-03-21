// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("HEVCEncoder parameterSets", .timeLimit(.minutes(1)))
struct HEVCParameterSetsTests {

    private func makeEncoder() -> HEVCEncoder {
        HEVCEncoder(encoderProvider: MockVideoEncoderProvider())
    }

    @Test("parameterSets is nil before encode")
    func parameterSetsNilBeforeEncode() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(hevc: .streaming1080p)
        let params = await encoder.parameterSets
        #expect(params == nil)
    }

    @Test("parameterSets is nil with mock provider")
    func parameterSetsNilWithMockProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(hevc: .streaming1080p)
        let frame = VideoFrame(
            data: Data(repeating: 0, count: 1024),
            format: VideoFormat(
                resolution: .p1080,
                frameRate: .fps30,
                pixelFormat: .bgra,
                colorSpace: .bt709,
                dynamicRange: .sdr,
                bitDepth: .bit8
            ),
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 1
        )
        _ = try await encoder.encode(frame)
        // Mock provider has no real CMFormatDescription
        let params = await encoder.parameterSets
        #expect(params == nil)
    }

    @Test("parameterSets is nil before configure")
    func parameterSetsNilBeforeConfigure() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let params = await encoder.parameterSets
        #expect(params == nil)
    }

    @Test("parameterSets is nil after reset")
    func parameterSetsNilAfterReset() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(hevc: .streaming1080p)
        await encoder.reset()
        let params = await encoder.parameterSets
        #expect(params == nil)
    }
}
