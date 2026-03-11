// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("StreamingPipeline")
struct StreamingPipelineTests {

    // MARK: - Helpers

    private func makeAudioBuffer(
        timestamp: TimeInterval = 0, seq: Int64 = 0
    ) -> CaptureKit.AudioBuffer {
        CaptureKit.AudioBuffer(
            data: Data(repeating: 0xAA, count: 960),
            format: AudioFormat(
                sampleRate: .rate48000, channelCount: 1),
            timestamp: timestamp,
            duration: 0.02,
            sequenceNumber: seq
        )
    }

    private func makeVideoFrame(
        timestamp: TimeInterval = 0, isKeyFrame: Bool = true, seq: Int64 = 0
    ) -> VideoFrame {
        VideoFrame(
            data: Data(repeating: 0x00, count: 1280 * 720 * 4),
            format: VideoFormat(
                resolution: .p720, frameRate: .fps30, pixelFormat: .bgra),
            timestamp: timestamp,
            isKeyFrame: isKeyFrame,
            sequenceNumber: seq
        )
    }

    /// Audio source that yields a fixed number of buffers then finishes.
    private func makeFiniteAudioSource(
        bufferCount: Int
    ) -> (PipelineTestAudioSource, [CaptureKit.AudioBuffer]) {
        var buffers: [CaptureKit.AudioBuffer] = []
        for i in 0..<bufferCount {
            buffers.append(makeAudioBuffer(
                timestamp: Double(i) * 0.02, seq: Int64(i)))
        }
        return (PipelineTestAudioSource(buffers: buffers), buffers)
    }

    /// Video source that yields a fixed number of frames then finishes.
    private func makeFiniteVideoSource(
        frameCount: Int
    ) -> (PipelineTestVideoSource, [VideoFrame]) {
        var frames: [VideoFrame] = []
        for i in 0..<frameCount {
            frames.append(makeVideoFrame(
                timestamp: Double(i) / 30.0,
                isKeyFrame: i == 0,
                seq: Int64(i)))
        }
        return (PipelineTestVideoSource(frames: frames), frames)
    }

    // MARK: - Audio Only

    @Test("audio only mode connects and sends packets")
    func audioOnlyMode() async throws {
        let (source, _) = makeFiniteAudioSource(bufferCount: 3)
        let encoder = MockAudioEncoder()
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: source, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()

        // Poll until packets arrive or timeout
        for _ in 0..<40 {
            if await transport.sentPackets.count >= 3 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        let packets = await transport.sentPackets
        #expect(packets.count == 3)
        for packet in packets {
            if case .audio = packet {
                // expected
            } else {
                Issue.record("Expected .audio packet")
            }
        }

        #expect(await transport.connectCallCount == 1)
        let stats = await pipeline.stats
        #expect(stats.isStreaming)
        #expect(stats.bytesSent > 0)

        await pipeline.stop()
        #expect(await transport.disconnectCallCount == 1)
    }

    // MARK: - Video Only

    @Test("video only mode connects and sends packets")
    func videoOnlyMode() async throws {
        let (source, _) = makeFiniteVideoSource(frameCount: 3)
        let encoder = MockVideoEncoder()
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .videoOnly(source: source, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()

        for _ in 0..<40 {
            if await transport.sentPackets.count >= 3 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        let packets = await transport.sentPackets
        #expect(packets.count == 3)
        for packet in packets {
            if case .video = packet {
                // expected
            } else {
                Issue.record("Expected .video packet")
            }
        }

        await pipeline.stop()
    }

    // MARK: - Muxed

    @Test("muxed mode interleaves audio and video")
    func muxedMode() async throws {
        let (audioSource, _) = makeFiniteAudioSource(bufferCount: 5)
        let (videoSource, _) = makeFiniteVideoSource(frameCount: 3)
        let audioEncoder = MockAudioEncoder()
        let videoEncoder = MockVideoEncoder()
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .muxed(
                videoSource: videoSource,
                videoEncoder: videoEncoder,
                audioSource: audioSource,
                audioEncoder: audioEncoder
            ),
            transport: transport
        )
        try await pipeline.start()

        // Wait for all 8 packets (5 audio + 3 video)
        for _ in 0..<60 {
            if await transport.sentPackets.count >= 8 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        let packets = await transport.sentPackets
        let audioCount = packets.filter {
            if case .audio = $0 { return true }
            return false
        }.count
        let videoCount = packets.filter {
            if case .video = $0 { return true }
            return false
        }.count

        #expect(audioCount == 5)
        #expect(videoCount == 3)

        await pipeline.stop()
    }

    // MARK: - Stats

    @Test("stats reflect sent data")
    func statsReflectData() async throws {
        let (source, _) = makeFiniteAudioSource(bufferCount: 2)
        let encoder = MockAudioEncoder()
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: source, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()

        for _ in 0..<40 {
            if await transport.sentPackets.count >= 2 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        let stats = await pipeline.stats
        #expect(stats.bytesSent > 0)
        #expect(stats.isStreaming)

        await pipeline.stop()
        let stoppedStats = await pipeline.stats
        #expect(stoppedStats.isStreaming == false)
    }

    // MARK: - Stop / Cancel

    @Test("stop disconnects transport")
    func stopDisconnectsTransport() async throws {
        let (source, _) = makeFiniteAudioSource(bufferCount: 1)
        let encoder = MockAudioEncoder()
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: source, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()

        for _ in 0..<40 {
            if await transport.sentPackets.count >= 1 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        await pipeline.stop()
        #expect(await transport.disconnectCallCount == 1)
        #expect(await transport.isConnected == false)
    }

    @Test("double start is idempotent")
    func doubleStartIdempotent() async throws {
        let (source, _) = makeFiniteAudioSource(bufferCount: 1)
        let encoder = MockAudioEncoder()
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: source, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()
        try await pipeline.start()

        #expect(await transport.connectCallCount == 1)
        await pipeline.stop()
    }

    @Test("double stop is idempotent")
    func doubleStopIdempotent() async throws {
        let (source, _) = makeFiniteAudioSource(bufferCount: 1)
        let encoder = MockAudioEncoder()
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: source, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()
        await pipeline.stop()
        await pipeline.stop()

        #expect(await transport.disconnectCallCount == 1)
    }

    @Test("connect failure propagates")
    func connectFailurePropagates() async throws {
        let (source, _) = makeFiniteAudioSource(bufferCount: 1)
        let encoder = MockAudioEncoder()
        let transport = MockStreamingTransport()
        await transport.setThrowOnConnect(true)

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: source, encoder: encoder),
            transport: transport
        )

        do {
            try await pipeline.start()
            Issue.record("Expected connect to throw")
        } catch {
            // expected
        }
    }
}

// MARK: - Test-only Sources

/// Audio source that yields a pre-defined sequence of buffers.
actor PipelineTestAudioSource: AudioSource {
    let sourceID = "test-audio"
    let displayName = "Test Audio"
    let sourceType: AudioSourceType = .microphone
    nonisolated let availability: SourceAvailability = .available

    private let buffers: [CaptureKit.AudioBuffer]

    var supportedFormats: [AudioFormat] { [] }
    var activeFormat: AudioFormat? { nil }
    var isCapturing: Bool { false }

    nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        AsyncStream { $0.finish() }
    }

    init(buffers: [CaptureKit.AudioBuffer]) {
        self.buffers = buffers
    }

    func configure(
        _ configuration: AudioSourceConfiguration
    ) async throws {}

    func startCapture() async throws -> AsyncStream<CaptureKit.AudioBuffer> {
        let captured = buffers
        return AsyncStream { continuation in
            for buffer in captured {
                continuation.yield(buffer)
            }
            continuation.finish()
        }
    }

    func stopCapture() async {}
}

/// Video source that yields a pre-defined sequence of frames.
actor PipelineTestVideoSource: VideoSource {
    let sourceID = "test-video"
    let displayName = "Test Video"
    let sourceType: VideoSourceType = .builtInCamera
    nonisolated let availability: SourceAvailability = .available

    private let frames: [VideoFrame]

    var supportedFormats: [VideoFormat] { [] }
    var activeFormat: VideoFormat? { nil }
    var isCapturing: Bool { false }

    nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        AsyncStream { $0.finish() }
    }

    init(frames: [VideoFrame]) {
        self.frames = frames
    }

    func configure(
        _ configuration: VideoSourceConfiguration
    ) async throws {}

    func startCapture() async throws -> AsyncStream<VideoFrame> {
        let captured = frames
        return AsyncStream { continuation in
            for frame in captured {
                continuation.yield(frame)
            }
            continuation.finish()
        }
    }

    func stopCapture() async {}
}

// MARK: - MockStreamingTransport helpers

extension MockStreamingTransport {
    func setThrowOnConnect(_ value: Bool) {
        shouldThrowOnConnect = value
    }
}
