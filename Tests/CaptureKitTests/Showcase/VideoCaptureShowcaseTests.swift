// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Video Capture Showcase", .tags(.showcase), .timeLimit(.minutes(1)))
struct VideoCaptureShowcaseTests {

    // MARK: - VideoResolution

    @Test("VideoResolution provides correct dimensions")
    func resolutionDimensions() {
        #expect(VideoResolution.vga.width == 640)
        #expect(VideoResolution.vga.height == 480)
        #expect(VideoResolution.p720.width == 1280)
        #expect(VideoResolution.p720.height == 720)
        #expect(VideoResolution.p1080.width == 1920)
        #expect(VideoResolution.p1080.height == 1080)
        #expect(VideoResolution.uhd4K.width == 3840)
        #expect(VideoResolution.uhd4K.height == 2160)
    }

    @Test("VideoResolution pixel counts increase with resolution")
    func resolutionPixelCounts() {
        let vgaPixels = VideoResolution.vga.width * VideoResolution.vga.height
        let hdPixels = VideoResolution.p720.width * VideoResolution.p720.height
        let fhdPixels = VideoResolution.p1080.width * VideoResolution.p1080.height
        let uhdPixels = VideoResolution.uhd4K.width * VideoResolution.uhd4K.height
        #expect(vgaPixels < hdPixels)
        #expect(hdPixels < fhdPixels)
        #expect(fhdPixels < uhdPixels)
    }

    // MARK: - FrameRate

    @Test("FrameRate values match expected fps")
    func frameRateValues() {
        #expect(FrameRate.fps24.value == 24.0)
        #expect(FrameRate.fps30.value == 30.0)
        #expect(FrameRate.fps60.value == 60.0)
        #expect(FrameRate.fps120.value == 120.0)
        #expect(FrameRate.fps240.value == 240.0)
    }

    // MARK: - VideoSourceConfiguration Presets

    @Test("Default video configuration is 1080p30 SDR")
    func defaultVideoConfig() {
        let config = VideoSourceConfiguration.default
        #expect(config.resolution == .p1080)
        #expect(config.frameRate == .fps30)
        #expect(config.dynamicRange == .sdr)
        #expect(config.colorSpace == .bt709)
    }

    @Test("Broadcast 720p preset has stabilization")
    func broadcast720pConfig() {
        let config = VideoSourceConfiguration.broadcast720p
        #expect(config.resolution == .p720)
        #expect(config.frameRate == .fps30)
        #expect(config.stabilization == .standard)
    }

    @Test("Pro 4K preset uses HDR10 and BT.2020")
    func pro4KConfig() {
        let config = VideoSourceConfiguration.pro4K
        #expect(config.resolution == .uhd4K)
        #expect(config.dynamicRange == .hdr10)
        #expect(config.colorSpace == .bt2020)
    }

    @Test("Cinematic preset uses 24fps")
    func cinematicConfig() {
        let config = VideoSourceConfiguration.cinematic
        #expect(config.frameRate == .fps24)
        #expect(config.colorSpace == .displayP3)
        #expect(config.stabilization == .cinematic)
    }

    // MARK: - MockVideoSource

    @Test("Configure mock video source for 1080p capture")
    func configureMockVideoSource() async throws {
        let source = MockVideoSource(
            sourceID: "test-camera",
            displayName: "Test Camera",
            sourceType: .builtInCamera
        )
        try await source.configure(.default)
        let format = await source.activeFormat
        #expect(format?.resolution == .p1080)
        #expect(format?.frameRate == .fps30)
        #expect(await source.configureCallCount == 1)
    }

    @Test("MockVideoSource start/stop lifecycle")
    func mockVideoLifecycle() async throws {
        let source = MockVideoSource()
        try await source.configure(.default)
        #expect(await source.isCapturing == false)

        _ = try await source.startCapture()
        #expect(await source.isCapturing == true)

        await source.stopCapture()
        #expect(await source.isCapturing == false)
        #expect(await source.startCaptureCallCount == 1)
        #expect(await source.stopCaptureCallCount == 1)
    }

    // MARK: - VideoFrame & EncodedVideoFrame

    @Test("Create VideoFrame with key frame flag")
    func createVideoFrame() {
        let frame = VideoFrame(
            data: Data(repeating: 0xFF, count: 1920 * 1080 * 4),
            format: VideoFormat(
                resolution: .p1080,
                frameRate: .fps30,
                pixelFormat: .bgra,
                colorSpace: .bt709,
                dynamicRange: .sdr
            ),
            timestamp: 0.033,
            isKeyFrame: true,
            sequenceNumber: 1
        )
        #expect(frame.isKeyFrame == true)
        #expect(frame.timestamp == 0.033)
    }

    @Test("EncodedVideoFrame withTimestamp creates new instance")
    func encodedFrameTimestamp() {
        let frame = EncodedVideoFrame(
            data: Data([0x00, 0x00, 0x01]),
            codec: .h264,
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 0
        )
        let updated = frame.withTimestamp(1.5)
        #expect(updated.timestamp == 1.5)
        #expect(updated.isKeyFrame == true)
        #expect(updated.codec == .h264)
        #expect(frame.timestamp == 0.0)
    }

    // MARK: - VideoFormat

    @Test("VideoFormat captures all configuration dimensions")
    func videoFormatProperties() {
        let format = VideoFormat(
            resolution: .p720,
            frameRate: .fps60,
            pixelFormat: .nv12,
            colorSpace: .bt709,
            dynamicRange: .sdr
        )
        #expect(format.resolution == .p720)
        #expect(format.frameRate == .fps60)
        #expect(format.pixelFormat == .nv12)
        #expect(format.colorSpace == .bt709)
        #expect(format.dynamicRange == .sdr)
    }
}
