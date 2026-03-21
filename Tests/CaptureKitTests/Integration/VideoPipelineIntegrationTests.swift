// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Video Pipeline Integration", .timeLimit(.minutes(1)))
struct VideoPipelineIntegrationTests {

    private func makeFrame(
        timestamp: TimeInterval = 0.0,
        sequenceNumber: Int64 = 0
    ) -> VideoFrame {
        let format = VideoFormat(
            resolution: .p1080,
            frameRate: .fps30,
            pixelFormat: .bgra,
            colorSpace: .bt709,
            dynamicRange: .sdr,
            bitDepth: .bit8
        )
        return VideoFrame(
            data: Data(repeating: 0xAA, count: 1920 * 1080 * 4),
            format: format,
            timestamp: timestamp,
            isKeyFrame: true,
            sequenceNumber: sequenceNumber
        )
    }

    @Test("BlackSource produces frames with correct resolution")
    func blackSourceProducesFrames() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource(resolution: .p720, frameRate: .fps30)
        let stream = try await source.startCapture()
        let frames = await collectValues(from: stream, count: 3)
        await source.stopCapture()
        #expect(frames.count >= 3)
        for frame in frames {
            #expect(frame.format.resolution == .p720)
        }
    }

    @Test("ColorSource produces frames")
    func colorSourceProducesFrames() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(
            color: CaptureColor(red: 1.0, green: 0.0, blue: 0.0),
            resolution: .vga, frameRate: .fps30
        )
        let stream = try await source.startCapture()
        let frames = await collectValues(from: stream, count: 2)
        await source.stopCapture()
        #expect(frames.count >= 2)
    }

    @Test("TestPatternSource produces frames")
    func testPatternSourceProducesFrames() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource(
            pattern: .smpteBars,
            resolution: .vga,
            frameRate: .fps30
        )
        let stream = try await source.startCapture()
        let frames = await collectValues(from: stream, count: 2)
        await source.stopCapture()
        #expect(frames.count >= 2)
    }

    @Test("mock encoder encodes frame and returns data")
    func mockEncoderEncodesFrame() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        let frame = makeFrame()
        let encoded = try await encoder.encode(frame)
        #expect(encoded.codec == .h264)
        #expect(encoded.data.count > 0)
    }

    @Test("pipeline: source → encoder → encoded frames")
    func pipelineSourceToEncoder() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)

        let source = BlackSource(resolution: .p1080, frameRate: .fps30)
        let stream = try await source.startCapture()
        let frames = await collectValues(from: stream, count: 3)
        await source.stopCapture()

        var encodedCount = 0
        for frame in frames {
            let encoded = try await encoder.encode(frame)
            #expect(encoded.codec == .h264)
            encodedCount += 1
        }
        #expect(encodedCount >= 3)
    }

    @Test("pipeline stop flushes encoder")
    func pipelineStopFlushesEncoder() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        let frame = makeFrame()
        _ = try await encoder.encode(frame)
        let flushed = try await encoder.flush()
        #expect(flushed.isEmpty)
    }

    @Test("file reader mock produces frames")
    func fileReaderMockProducesFrames() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let reader = MockVideoFileReader()
        let sample = CapturedVideoSample(
            data: Data(repeating: 0xBB, count: 100),
            timestamp: 1.0,
            format: VideoFormat(
                resolution: .p720,
                frameRate: .fps30,
                pixelFormat: .bgra,
                colorSpace: .bt709,
                dynamicRange: .sdr
            ),
            isKeyFrame: true
        )
        await reader.setSamples([sample])

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_pipeline_\(UUID().uuidString).mp4")
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00]))
        defer { try? FileManager.default.removeItem(at: url) }

        let source = FileVideoSource(url: url, fileReader: reader)
        let stream = try await source.startCapture()
        var frames: [VideoFrame] = []
        for await frame in stream {
            frames.append(frame)
        }
        #expect(frames.count == 1)
        #expect(frames[0].timestamp == 1.0)
        await source.stopCapture()
    }

    @Test("multi-camera mock produces per-label streams")
    func multiCameraMockProducesStreams() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let sample = CapturedVideoSample(
            data: Data(repeating: 0xCC, count: 100),
            timestamp: 0.5,
            format: VideoFormat(
                resolution: .p1080,
                frameRate: .fps30,
                pixelFormat: .bgra,
                colorSpace: .bt709,
                dynamicRange: .sdr
            ),
            isKeyFrame: true
        )
        await engine.setSamples([sample])

        let dev1 = VideoDeviceInfo(id: "cam-1", name: "Camera 1", connectionType: .usb)
        let dev2 = VideoDeviceInfo(id: "cam-2", name: "Camera 2", connectionType: .usb)
        let config = MultiCameraConfiguration(cameras: [
            MultiCameraInput(device: dev1, label: "host"),
            MultiCameraInput(device: dev2, label: "guest")
        ])
        let source = MultiCameraSource(configuration: config, captureEngine: engine)
        let stream = try await source.stream(for: "host")
        var frames: [VideoFrame] = []
        for await frame in stream {
            frames.append(frame)
        }
        #expect(frames.count == 1)
        #expect(frames[0].timestamp == 0.5)
    }

    @Test("encoder reset clears configured state")
    func encoderResetClearsState() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = HEVCEncoder(encoderProvider: provider)
        try await encoder.configure(hevc: .streaming1080p)
        let beforeReset = await encoder.isConfigured
        #expect(beforeReset == true)
        await encoder.reset()
        let afterReset = await encoder.isConfigured
        #expect(afterReset == false)
    }

    @Test("forceKeyFrame marks next frame as key")
    func forceKeyFrameMarksNextFrame() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockVideoEncoderProvider()
        let encoder = H264Encoder(encoderProvider: provider)
        try await encoder.configure(h264: .streaming1080p)
        try await encoder.forceKeyFrame()
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
            isKeyFrame: false,
            sequenceNumber: 0
        )
        let encoded = try await encoder.encode(frame)
        #expect(encoded.isKeyFrame == true)
    }
}
