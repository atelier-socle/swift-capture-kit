// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("JPEGEncoder", .timeLimit(.minutes(1)))
struct JPEGEncoderTests {

    private func makeEncoder() -> JPEGEncoder {
        JPEGEncoder(encoderProvider: MockVideoEncoderProvider())
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

    @Test("codec is jpeg")
    func codecIsJpeg() {
        let encoder = makeEncoder()
        #expect(encoder.codec == .jpeg)
    }

    @Test("supported bit rates is 0 (quality-based)")
    func supportedBitRatesIsZero() {
        let encoder = makeEncoder()
        #expect(encoder.supportedBitRates == 0...0)
    }

    @Test("supported profiles is baseline")
    func supportedProfilesIsBaseline() {
        let encoder = makeEncoder()
        #expect(encoder.supportedProfiles == ["baseline"])
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
        try await encoder.configure(jpeg: .standard)
        let configured = await encoder.isConfigured
        #expect(configured == true)
    }

    @Test("encode always produces keyframe")
    func encodeAlwaysProducesKeyframe() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(jpeg: .standard)
        let frame = makeFrame(isKeyFrame: false)
        let encoded = try await encoder.encode(frame)
        #expect(encoded.isKeyFrame == true)
    }

    @Test("forceKeyFrame is a no-op")
    func forceKeyFrameIsNoOp() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.forceKeyFrame()
    }

    @Test("updateBitrate is a no-op")
    func updateBitrateIsNoOp() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(jpeg: .standard)
        try await encoder.updateBitrate(5_000_000)
    }

    // MARK: - Generic configure path

    @Test("generic configure sets isConfigured")
    func genericConfigure() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let config = VideoEncoderConfiguration(
            bitrate: 0,
            resolution: .p1080,
            frameRate: .fps30,
            keyFrameInterval: 1,
            realTime: true
        )
        try await encoder.configure(config)
        #expect(await encoder.isConfigured == true)
    }

    // MARK: - Flush / Reset

    @Test("flush returns empty when no data buffered")
    func flushReturnsEmpty() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(jpeg: .standard)
        let result = try await encoder.flush()
        #expect(result.isEmpty)
    }

    @Test("reset clears isConfigured")
    func resetClearsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(jpeg: .standard)
        #expect(await encoder.isConfigured == true)
        await encoder.reset()
        #expect(await encoder.isConfigured == false)
    }

    // MARK: - Encode before configure

    @Test("encode before configure throws")
    func encodeBeforeConfigureThrows() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            try await encoder.encode(frame)
        }
    }

    // MARK: - Configuration Presets

    @Test("highQuality preset has 0.95 quality")
    func highQualityPreset() {
        let config = JPEGEncoderConfiguration.highQuality
        #expect(config.quality == 0.95)
    }

    @Test("standard preset has 0.85 quality")
    func standardPreset() {
        let config = JPEGEncoderConfiguration.standard
        #expect(config.quality == 0.85)
    }

    @Test("lowBandwidth preset has 0.5 quality")
    func lowBandwidthPreset() {
        let config = JPEGEncoderConfiguration.lowBandwidth
        #expect(config.quality == 0.5)
    }

    // MARK: - Configuration Validation

    @Test("quality above 1.0 fails validation")
    func qualityAboveOneThrows() {
        let config = JPEGEncoderConfiguration(quality: 1.5)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("quality below 0.0 fails validation")
    func qualityBelowZeroThrows() {
        let config = JPEGEncoderConfiguration(quality: -0.1)
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("quality 0.0 is valid")
    func qualityZeroIsValid() throws {
        let config = JPEGEncoderConfiguration(quality: 0.0)
        try config.validate()
    }

    @Test("quality 1.0 is valid")
    func qualityOneIsValid() throws {
        let config = JPEGEncoderConfiguration(quality: 1.0)
        try config.validate()
    }

    // MARK: - Supported properties

    @Test("supported resolutions include common sizes")
    func supportedResolutions() {
        let encoder = makeEncoder()
        #expect(encoder.supportedResolutions.contains(.p1080))
        #expect(encoder.supportedResolutions.contains(.vga))
    }

    @Test("supported frame rates include low fps")
    func supportedFrameRates() {
        let encoder = makeEncoder()
        #expect(encoder.supportedFrameRates.contains(.fps1))
        #expect(encoder.supportedFrameRates.contains(.fps30))
    }

    @Test("is hardware accelerated")
    func isHardwareAccelerated() {
        let encoder = makeEncoder()
        #expect(encoder.isHardwareAccelerated == true)
    }

    // MARK: - Provider Error Propagation

    @Test("configure propagates provider error")
    func configurePropagatesToProviderError() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        await provider.setThrowOnConfigure(true)
        let encoder = JPEGEncoder(encoderProvider: provider)
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(jpeg: .standard)
        }
    }

    @Test("encode propagates provider error")
    func encodePropagatesToProviderError() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = JPEGEncoder(encoderProvider: provider)
        try await encoder.configure(jpeg: .standard)
        await provider.setThrowOnEncode(true)
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            try await encoder.encode(frame)
        }
    }
}
