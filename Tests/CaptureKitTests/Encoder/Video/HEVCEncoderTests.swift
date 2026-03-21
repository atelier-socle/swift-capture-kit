// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("HEVCEncoder")
struct HEVCEncoderTests {

    private func makeEncoder() -> HEVCEncoder {
        HEVCEncoder(encoderProvider: MockVideoEncoderProvider())
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

    // MARK: - Generic configure path

    @Test("generic configure sets isConfigured")
    func genericConfigure() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let config = VideoEncoderConfiguration(
            bitrate: 5_000_000,
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
        try await encoder.configure(hevc: .streaming1080p)
        let result = try await encoder.flush()
        #expect(result.isEmpty)
    }

    @Test("reset clears isConfigured")
    func resetClearsIsConfigured() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(hevc: .streaming1080p)
        #expect(await encoder.isConfigured == true)
        await encoder.reset()
        #expect(await encoder.isConfigured == false)
    }

    // MARK: - forceKeyFrame / updateBitrate

    @Test("forceKeyFrame calls provider")
    func forceKeyFrameCallsProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = HEVCEncoder(encoderProvider: provider)
        try await encoder.configure(hevc: .streaming1080p)
        try await encoder.forceKeyFrame()
        #expect(await provider.forceKeyFrameCallCount == 1)
    }

    @Test("updateBitrate updates configuration")
    func updateBitrateUpdatesConfig() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(hevc: .streaming1080p)
        try await encoder.updateBitrate(10_000_000)
        let config = await encoder.configuration
        #expect(config.bitrate == 10_000_000)
    }

    // MARK: - Configuration Presets

    @Test("hdr4K preset uses main10 and HDR10")
    func hdr4KPreset() {
        let config = HEVCEncoderConfiguration.hdr4K
        #expect(config.profile == .main10)
        #expect(config.hdrMode == .hdr10)
        #expect(config.bitrate == 25_000_000)
    }

    @Test("hlgBroadcast preset uses HLG")
    func hlgBroadcastPreset() {
        let config = HEVCEncoderConfiguration.hlgBroadcast
        #expect(config.hdrMode == .hlg)
        #expect(config.profile == .main10)
    }

    @Test("screenRecording preset values")
    func screenRecordingPreset() {
        let config = HEVCEncoderConfiguration.screenRecording
        #expect(config.profile == .main)
        #expect(config.bitrate == 8_000_000)
    }

    // MARK: - Configuration Validation

    @Test("HLG with main profile throws")
    func hlgWithMainProfileThrows() {
        let config = HEVCEncoderConfiguration(
            profile: .main,
            hdrMode: .hlg
        )
        #expect(throws: CaptureError.self) {
            try config.validate()
        }
    }

    @Test("SDR with main profile is valid")
    func sdrWithMainProfileValid() throws {
        let config = HEVCEncoderConfiguration(
            profile: .main,
            hdrMode: .sdr
        )
        try config.validate()
    }

    // MARK: - Provider Error Propagation

    @Test("configure propagates provider error")
    func configurePropagatesToProviderError() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        await provider.setThrowOnConfigure(true)
        let encoder = HEVCEncoder(encoderProvider: provider)
        await #expect(throws: CaptureError.self) {
            try await encoder.configure(hevc: .streaming1080p)
        }
    }

    @Test("encode propagates provider error")
    func encodePropagatesToProviderError() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = HEVCEncoder(encoderProvider: provider)
        try await encoder.configure(hevc: .streaming1080p)
        await provider.setThrowOnEncode(true)
        let frame = makeFrame()
        await #expect(throws: CaptureError.self) {
            try await encoder.encode(frame)
        }
    }

    // MARK: - Supported profiles

    @Test("supported profiles includes all HEVC profiles")
    func supportedProfilesAll() {
        let encoder = makeEncoder()
        let profiles = encoder.supportedProfiles
        #expect(profiles.count == HEVCProfile.allCases.count)
    }

    // MARK: - parameterSets nil with mock

    @Test("parameterSets returns nil with mock provider")
    func parameterSetsNilWithMock() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let encoder = makeEncoder()
        let sets = await encoder.parameterSets
        #expect(sets == nil)
    }
}
