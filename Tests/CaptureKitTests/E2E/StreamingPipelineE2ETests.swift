// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Streaming Pipeline E2E", .tags(.e2e), .timeLimit(.minutes(1)))
struct StreamingPipelineE2ETests {

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
        timestamp: TimeInterval = 0, isKeyFrame: Bool = true,
        seq: Int64 = 0
    ) -> VideoFrame {
        VideoFrame(
            data: Data(repeating: 0x00, count: 1280 * 720 * 4),
            format: VideoFormat(
                resolution: .p720, frameRate: .fps30,
                pixelFormat: .bgra),
            timestamp: timestamp,
            isKeyFrame: isKeyFrame,
            sequenceNumber: seq
        )
    }

    // MARK: - Muxed Pipeline E2E

    @Test("Muxed pipeline interleaves audio and video packets")
    func muxedInterleaving() async throws {
        let audioSource = E2EIntervalAudioSource(
            buffers: (0..<20).map { i in
                makeAudioBuffer(
                    timestamp: Double(i) * 0.02, seq: Int64(i))
            },
            intervalMilliseconds: 20
        )
        let videoSource = E2EDelayedVideoSource(
            frames: (0..<5).map { i in
                makeVideoFrame(
                    timestamp: Double(i) / 30.0,
                    isKeyFrame: i == 0,
                    seq: Int64(i))
            },
            delayMilliseconds: 50
        )
        let audioEncoder = MockAudioEncoder(codec: .aac)
        let videoEncoder = MockVideoEncoder(codec: .h264)
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

        for _ in 0..<80 {
            let count = await transport.sentPackets.count
            if count >= 8 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        await pipeline.stop()

        let packets = await transport.sentPackets
        let audioCount = packets.filter {
            if case .audio = $0 { return true }
            return false
        }.count
        let videoCount = packets.filter {
            if case .video = $0 { return true }
            return false
        }.count

        #expect(videoCount == 5, "All 5 video frames must arrive")
        #expect(audioCount >= 1, "At least some audio after gate opens")

        // Verify interleaving: both types present
        #expect(audioCount > 0 && videoCount > 0)
    }

    @Test("Muxed pipeline gates audio until first video frame")
    func muxedAudioGate() async throws {
        let audioSource = E2EIntervalAudioSource(
            buffers: (0..<10).map { i in
                makeAudioBuffer(
                    timestamp: Double(i) * 0.02, seq: Int64(i))
            },
            intervalMilliseconds: 20
        )
        let videoSource = E2EDelayedVideoSource(
            frames: [
                makeVideoFrame(
                    timestamp: 0.0, isKeyFrame: true, seq: 0)
            ],
            delayMilliseconds: 100
        )
        let audioEncoder = MockAudioEncoder(codec: .aac)
        let videoEncoder = MockVideoEncoder(codec: .h264)
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

        for _ in 0..<80 {
            let count = await transport.sentPackets.count
            if count >= 2 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        await pipeline.stop()

        let packets = await transport.sentPackets
        guard let first = packets.first else {
            Issue.record("No packets received")
            return
        }

        if case .video = first {
            // Expected: first packet is video due to audio gate
        } else {
            Issue.record(
                "First packet should be video (audio is gated)")
        }
    }

    @Test("Pipeline stats reflect data after streaming")
    func pipelineStats() async throws {
        let audioSource = E2EIntervalAudioSource(
            buffers: (0..<5).map { i in
                makeAudioBuffer(
                    timestamp: Double(i) * 0.02, seq: Int64(i))
            },
            intervalMilliseconds: 20
        )
        let encoder = MockAudioEncoder(codec: .aac)
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: audioSource, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()

        for _ in 0..<80 {
            let s = await pipeline.stats
            if s.bytesSent > 0 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        let stats = await pipeline.stats
        #expect(stats.isStreaming == true)
        #expect(stats.bytesSent > 0)

        await pipeline.stop()

        let stopped = await pipeline.stats
        #expect(stopped.isStreaming == false)
    }

    @Test("Transport connect failure prevents pipeline start")
    func connectFailure() async throws {
        let audioSource = E2EIntervalAudioSource(
            buffers: [makeAudioBuffer()],
            intervalMilliseconds: 20
        )
        let encoder = MockAudioEncoder()
        let transport = MockStreamingTransport()
        await transport.setThrowOnConnect(true)

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: audioSource, encoder: encoder),
            transport: transport
        )

        do {
            try await pipeline.start()
            Issue.record("Expected start to throw on connect failure")
        } catch {
            // Expected
        }
    }

    @Test("Pipeline stop is idempotent")
    func stopIdempotent() async throws {
        let audioSource = E2EIntervalAudioSource(
            buffers: [makeAudioBuffer()],
            intervalMilliseconds: 20
        )
        let encoder = MockAudioEncoder()
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: audioSource, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()

        for _ in 0..<40 {
            if await transport.sentPackets.count >= 1 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        await pipeline.stop()
        await pipeline.stop()

        #expect(await transport.disconnectCallCount == 1)
    }
}

// MARK: - E2E Test Sources

actor E2EIntervalAudioSource: AudioSource {
    let sourceID = "e2e-audio"
    let displayName = "E2E Audio"
    let sourceType: AudioSourceType = .microphone
    nonisolated let availability: SourceAvailability = .available

    private let buffers: [CaptureKit.AudioBuffer]
    private let intervalMilliseconds: Int

    var supportedFormats: [AudioFormat] { [] }
    var activeFormat: AudioFormat? { nil }
    var isCapturing: Bool { false }

    nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        AsyncStream { $0.finish() }
    }

    init(
        buffers: [CaptureKit.AudioBuffer],
        intervalMilliseconds: Int
    ) {
        self.buffers = buffers
        self.intervalMilliseconds = intervalMilliseconds
    }

    func configure(
        _ configuration: AudioSourceConfiguration
    ) async throws {}

    func startCapture() async throws -> AsyncStream<
        CaptureKit.AudioBuffer
    > {
        let captured = buffers
        let interval = intervalMilliseconds
        return AsyncStream { continuation in
            Task {
                for buffer in captured {
                    continuation.yield(buffer)
                    try? await Task.sleep(
                        for: .milliseconds(interval))
                }
                continuation.finish()
            }
        }
    }

    func stopCapture() async {}
}

actor E2EDelayedVideoSource: VideoSource {
    let sourceID = "e2e-video"
    let displayName = "E2E Video"
    let sourceType: VideoSourceType = .builtInCamera
    nonisolated let availability: SourceAvailability = .available

    private let frames: [VideoFrame]
    private let delayMilliseconds: Int

    var supportedFormats: [VideoFormat] { [] }
    var activeFormat: VideoFormat? { nil }
    var isCapturing: Bool { false }

    nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        AsyncStream { $0.finish() }
    }

    init(frames: [VideoFrame], delayMilliseconds: Int) {
        self.frames = frames
        self.delayMilliseconds = delayMilliseconds
    }

    func configure(
        _ configuration: VideoSourceConfiguration
    ) async throws {}

    func startCapture() async throws -> AsyncStream<VideoFrame> {
        let captured = frames
        let delay = delayMilliseconds
        return AsyncStream { continuation in
            Task {
                try? await Task.sleep(for: .milliseconds(delay))
                for frame in captured {
                    continuation.yield(frame)
                }
                continuation.finish()
            }
        }
    }

    func stopCapture() async {}
}
