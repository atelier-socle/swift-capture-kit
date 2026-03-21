// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ProResEncoder", .timeLimit(.minutes(1)))
struct ProResEncoderTests {

    private func makeEncoder() -> ProResEncoder {
        ProResEncoder(encoderProvider: MockVideoEncoderProvider())
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
        try await encoder.configure(prores: .hq)
        let result = try await encoder.flush()
        #expect(result.isEmpty)
    }

    @Test("reset clears isConfigured")
    func resetClearsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(prores: .hq)
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

    @Test("proxy preset uses proxy profile")
    func proxyPreset() {
        let config = ProResEncoderConfiguration.proxy
        #expect(config.profile == .proxy)
    }

    @Test("lt preset uses lt profile")
    func ltPreset() {
        let config = ProResEncoderConfiguration.lt
        #expect(config.profile == .lt)
    }

    @Test("standard preset uses standard profile")
    func standardPreset() {
        let config = ProResEncoderConfiguration.standard
        #expect(config.profile == .standard)
    }

    @Test("p4444 preset uses p4444 profile")
    func p4444Preset() {
        let config = ProResEncoderConfiguration.p4444
        #expect(config.profile == .p4444)
    }

    @Test("p4444xq preset uses p4444xq profile")
    func p4444xqPreset() {
        let config = ProResEncoderConfiguration.p4444xq
        #expect(config.profile == .p4444xq)
    }

    // MARK: - Supported properties

    @Test("supported resolutions include production formats")
    func supportedResolutions() {
        let encoder = makeEncoder()
        #expect(encoder.supportedResolutions.contains(.p1080))
        #expect(encoder.supportedResolutions.contains(.uhd4K))
        #expect(encoder.supportedResolutions.contains(.uhd8K))
    }

    @Test("supported frame rates include cinema rates")
    func supportedFrameRates() {
        let encoder = makeEncoder()
        #expect(encoder.supportedFrameRates.contains(.fps24))
        #expect(encoder.supportedFrameRates.contains(.fps30))
    }

    @Test("supported profiles includes all ProRes profiles")
    func supportedProfiles() {
        let encoder = makeEncoder()
        #expect(encoder.supportedProfiles.count == ProResProfile.allCases.count)
    }

    // MARK: - Provider Error Propagation

    @Test("configure propagates provider error")
    func configurePropagatesToProviderError() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        await provider.setThrowOnConfigure(true)
        let encoder = ProResEncoder(encoderProvider: provider)
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(prores: .hq)
        }
    }

    @Test("encode propagates provider error")
    func encodePropagatesToProviderError() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = ProResEncoder(encoderProvider: provider)
        try await encoder.configure(prores: .hq)
        await provider.setThrowOnEncode(true)
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            try await encoder.encode(frame)
        }
    }
}
