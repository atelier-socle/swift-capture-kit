// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("MVHEVCEncoder", .timeLimit(.minutes(1)))
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

    // MARK: - Generic configure path

    @Test("generic configure sets isConfigured")
    func genericConfigure() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let config = VideoEncoderConfiguration(
            bitrate: 25_000_000,
            resolution: .p1080,
            frameRate: .fps30,
            keyFrameInterval: 60,
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
        try await encoder.configure(mvhevc: .spatialVideo)
        let result = try await encoder.flush()
        #expect(result.isEmpty)
    }

    @Test("reset clears isConfigured")
    func resetClearsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(mvhevc: .spatialVideo)
        #expect(await encoder.isConfigured == true)
        await encoder.reset()
        #expect(await encoder.isConfigured == false)
    }

    // MARK: - forceKeyFrame / updateBitrate

    @Test("forceKeyFrame calls provider")
    func forceKeyFrameCallsProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = MVHEVCEncoder(encoderProvider: provider)
        try await encoder.configure(mvhevc: .spatialVideo)
        try await encoder.forceKeyFrame()
        #expect(await provider.forceKeyFrameCallCount == 1)
    }

    @Test("updateBitrate updates configuration")
    func updateBitrateUpdatesConfig() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(mvhevc: .spatialVideo)
        try await encoder.updateBitrate(40_000_000)
        let config = await encoder.configuration
        #expect(config.bitrate == 40_000_000)
    }

    // MARK: - Configuration Presets

    @Test("spatialVideo preset has 25 Mbps")
    func spatialVideoPreset() {
        let config = MVHEVCEncoderConfiguration.spatialVideo
        #expect(config.bitrate == 25_000_000)
    }

    @Test("spatialVideoHQ preset has 40 Mbps")
    func spatialVideoHQPreset() {
        let config = MVHEVCEncoderConfiguration.spatialVideoHQ
        #expect(config.bitrate == 40_000_000)
    }

    // MARK: - Supported properties

    @Test("supported resolutions include spatialVideo")
    func supportedResolutions() {
        let encoder = makeEncoder()
        #expect(encoder.supportedResolutions.contains(.spatialVideo))
        #expect(encoder.supportedResolutions.contains(.p1080))
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
        let encoder = MVHEVCEncoder(encoderProvider: provider)
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(mvhevc: .spatialVideo)
        }
    }

    @Test("encode propagates provider error")
    func encodePropagatesToProviderError() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = MVHEVCEncoder(encoderProvider: provider)
        try await encoder.configure(mvhevc: .spatialVideo)
        await provider.setThrowOnEncode(true)
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            try await encoder.encode(frame)
        }
    }
}
