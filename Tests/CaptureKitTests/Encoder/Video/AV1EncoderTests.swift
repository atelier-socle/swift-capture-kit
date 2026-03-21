// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AV1Encoder")
struct AV1EncoderTests {

    private func makeEncoder() -> AV1Encoder {
        AV1Encoder(encoderProvider: MockVideoEncoderProvider())
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

    // MARK: - Generic configure path

    @Test("generic configure sets isConfigured")
    func genericConfigure() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let config = VideoEncoderConfiguration(
            bitrate: 4_000_000,
            resolution: .p1080,
            frameRate: .fps30,
            keyFrameInterval: 60,
            realTime: true
        )
        try await encoder.configure(config)
        #expect(await encoder.isConfigured == true)
    }

    // MARK: - Flush

    @Test("flush returns empty when no data buffered")
    func flushReturnsEmpty() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(av1: .streaming1080p)
        let result = try await encoder.flush()
        #expect(result.isEmpty)
    }

    // MARK: - Configuration Presets

    @Test("streaming1080p preset has 4 Mbps")
    func streaming1080pPreset() {
        let config = AV1EncoderConfiguration.streaming1080p
        #expect(config.bitrate == 4_000_000)
    }

    @Test("streaming4K preset has 15 Mbps")
    func streaming4KPreset() {
        let config = AV1EncoderConfiguration.streaming4K
        #expect(config.bitrate == 15_000_000)
    }

    @Test("archive preset has 30 Mbps")
    func archivePreset() {
        let config = AV1EncoderConfiguration.archive
        #expect(config.bitrate == 30_000_000)
    }

    // MARK: - Supported properties

    @Test("is hardware accelerated reflects device capability")
    func hardwareAcceleration() {
        let encoder = makeEncoder()
        _ = encoder.isHardwareAccelerated
    }

    @Test("supported frame rates include common rates")
    func supportedFrameRates() {
        let encoder = makeEncoder()
        #expect(encoder.supportedFrameRates.contains(.fps30))
        #expect(encoder.supportedFrameRates.contains(.fps60))
    }

    @Test("supported bit rates upper bound")
    func supportedBitRatesUpperBound() {
        let encoder = makeEncoder()
        #expect(encoder.supportedBitRates.contains(100_000_000))
    }

    @Test("supported profiles includes all AV1 profiles")
    func supportedProfilesAll() {
        let encoder = makeEncoder()
        let profiles = encoder.supportedProfiles
        #expect(profiles.count == AV1Profile.allCases.count)
    }

    // MARK: - Provider Error Propagation

    @Test("configure propagates provider error")
    func configurePropagatesToProviderError() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        await provider.setThrowOnConfigure(true)
        let encoder = AV1Encoder(encoderProvider: provider)
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(av1: .streaming1080p)
        }
    }

    @Test("encode propagates provider error")
    func encodePropagatesToProviderError() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = AV1Encoder(encoderProvider: provider)
        try await encoder.configure(av1: .streaming1080p)
        await provider.setThrowOnEncode(true)
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            try await encoder.encode(frame)
        }
    }
}
