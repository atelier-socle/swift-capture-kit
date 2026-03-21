// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("H264Encoder", .timeLimit(.minutes(1)))
struct H264EncoderTests {

    private func makeEncoder() -> H264Encoder {
        H264Encoder(encoderProvider: MockVideoEncoderProvider())
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

    // MARK: - Generic configure path

    @Test("generic configure sets isConfigured")
    func genericConfigure() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let config = VideoEncoderConfiguration(
            bitrate: 4_500_000,
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
        try await encoder.configure(h264: .streaming1080p)
        let result = try await encoder.flush()
        #expect(result.isEmpty)
    }

    @Test("reset clears isConfigured")
    func resetClearsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(h264: .streaming1080p)
        #expect(await encoder.isConfigured == true)
        await encoder.reset()
        #expect(await encoder.isConfigured == false)
    }

    // MARK: - forceKeyFrame / updateBitrate

    @Test("forceKeyFrame sets pendingKeyFrame")
    func forceKeyFrameSetsFlag() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        try await encoder.forceKeyFrame()
        #expect(await provider.forceKeyFrameCallCount == 1)
    }

    @Test("updateBitrate updates configuration")
    func updateBitrateUpdatesConfig() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(h264: .streaming1080p)
        try await encoder.updateBitrate(8_000_000)
        let config = await encoder.configuration
        #expect(config.bitrate == 8_000_000)
    }

    // MARK: - Configuration Presets

    @Test("streaming720p preset values")
    func streaming720pPreset() {
        let config = H264EncoderConfiguration.streaming720p
        #expect(config.resolution == .p720)
        #expect(config.bitrate == 2_500_000)
    }

    @Test("lowLatency preset uses baseline and no bFrames")
    func lowLatencyPreset() {
        let config = H264EncoderConfiguration.lowLatency
        #expect(config.profile == .baseline)
        #expect(config.bFrames == false)
        #expect(config.entropyMode == .cavlc)
    }

    @Test("archive preset uses high profile")
    func archivePreset() {
        let config = H264EncoderConfiguration.archive
        #expect(config.profile == .high)
        #expect(config.bitrate == 20_000_000)
    }

    // MARK: - Configuration Validation

    @Test("baseline with CABAC throws")
    func baselineWithCABACThrows() {
        let config = H264EncoderConfiguration(
            profile: .baseline,
            entropyMode: .cabac
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("valid config passes validation")
    func validConfigPasses() throws {
        let config = H264EncoderConfiguration.streaming1080p
        try config.validate()
    }

    // MARK: - Provider Error Propagation

    @Test("configure propagates provider error")
    func configurePropagatesToProviderError() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        await provider.setThrowOnConfigure(true)
        let encoder = H264Encoder(encoderProvider: provider)
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(h264: .streaming1080p)
        }
    }

    @Test("encode propagates provider error")
    func encodePropagatesToProviderError() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        await provider.setThrowOnEncode(true)
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            try await encoder.encode(frame)
        }
    }

    // MARK: - Supported profiles

    @Test("supported profiles includes all H264 profiles")
    func supportedProfilesAll() {
        let encoder = makeEncoder()
        let profiles = encoder.supportedProfiles
        #expect(profiles.count == H264Profile.allCases.count)
    }

    // MARK: - parameterSets nil before encoding

    @Test("parameterSets returns nil with mock provider")
    func parameterSetsNilWithMock() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let sets = await encoder.parameterSets
        #expect(sets == nil)
    }
}
