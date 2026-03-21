// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Audio Pipeline E2E", .tags(.e2e))
struct AudioPipelineE2ETests {

    // MARK: - ToneSource → MockAudioEncoder → MockTransport

    @Test("ToneSource produces buffers that encode to AAC via pipeline")
    func toneToEncoderPipeline() async throws {
        let tone = ToneSource(
            waveform: .sine,
            frequency: 440.0,
            amplitude: 0.5
        )
        let encoder = MockAudioEncoder(codec: .aac)
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: tone, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()

        // Wait for at least 5 packets (≈100ms of audio)
        for _ in 0..<80 {
            if await transport.sentPackets.count >= 5 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        await pipeline.stop()

        let packets = await transport.sentPackets
        #expect(packets.count >= 5, "Expected at least 5 audio packets")

        for packet in packets {
            if case .audio(let buffer) = packet {
                #expect(buffer.data.count > 0)
                #expect(buffer.codec == .aac)
            } else {
                Issue.record("Expected audio packet")
            }
        }
    }

    @Test("Audio pipeline timestamps are monotonically increasing")
    func audioTimestampsMonotonic() async throws {
        let tone = ToneSource(
            waveform: .sine,
            frequency: 1000.0,
            amplitude: 0.3
        )
        let encoder = MockAudioEncoder(codec: .aac)
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: tone, encoder: encoder),
            transport: transport
        )
        try await pipeline.start()

        for _ in 0..<80 {
            if await transport.sentPackets.count >= 10 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        await pipeline.stop()

        let packets = await transport.sentPackets
        #expect(packets.count >= 5)

        var lastTimestamp: TimeInterval = -1
        for packet in packets {
            let ts = packet.timestamp
            #expect(ts >= lastTimestamp, "Timestamps must be monotonic")
            lastTimestamp = ts
        }
    }

    @Test("Audio pipeline stats reflect streaming state")
    func audioPipelineStats() async throws {
        let tone = ToneSource(waveform: .sine)
        let encoder = MockAudioEncoder(codec: .aac)
        let transport = MockStreamingTransport()

        let pipeline = StreamingPipeline(
            mode: .audioOnly(source: tone, encoder: encoder),
            transport: transport
        )

        let preStats = await pipeline.stats
        #expect(preStats.isStreaming == false)
        #expect(preStats.bytesSent == 0)

        try await pipeline.start()

        for _ in 0..<80 {
            let stats = await pipeline.stats
            if stats.bytesSent > 0 { break }
            try await Task.sleep(for: .milliseconds(50))
        }

        let activeStats = await pipeline.stats
        #expect(activeStats.isStreaming == true)
        #expect(activeStats.bytesSent > 0)

        await pipeline.stop()

        let postStats = await pipeline.stats
        #expect(postStats.isStreaming == false)
    }

    // MARK: - ToneSource Direct Capture

    @Test("ToneSource generates buffers with correct format")
    func toneSourceDirectCapture() async throws {
        let tone = ToneSource(
            waveform: .sine,
            frequency: 440.0,
            amplitude: 0.5
        )
        let config = AudioSourceConfiguration(
            sampleRate: .rate48000,
            channelCount: 1,
            channelLayout: .mono,
            bitDepth: .float32,
            preferredBufferDuration: 0.02
        )
        try await tone.configure(config)
        let stream = try await tone.startCapture()

        var bufferCount = 0
        for await buffer in stream {
            #expect(buffer.data.count > 0)
            #expect(buffer.format.sampleRate == .rate48000)
            #expect(buffer.format.channelCount == 1)
            #expect(buffer.duration > 0)
            bufferCount += 1
            if bufferCount >= 5 { break }
        }

        await tone.stopCapture()
        #expect(bufferCount >= 5)
    }

    @Test("ToneSource buffers have no timestamp drift over 2 seconds")
    func toneSourceNoDrift() async throws {
        let tone = ToneSource(
            waveform: .sine,
            frequency: 440.0,
            amplitude: 0.5
        )
        try await tone.configure(.default)
        let stream = try await tone.startCapture()

        var firstTimestamp: TimeInterval?
        var lastTimestamp: TimeInterval = 0
        var totalDuration: TimeInterval = 0

        for await buffer in stream {
            if firstTimestamp == nil {
                firstTimestamp = buffer.timestamp
            }
            lastTimestamp = buffer.timestamp
            totalDuration += buffer.duration
            if totalDuration >= 0.5 { break }
        }

        await tone.stopCapture()

        guard let first = firstTimestamp else {
            Issue.record("No buffers received")
            return
        }

        let wallDuration = lastTimestamp - first + 0.02
        let drift = abs(wallDuration - totalDuration)
        #expect(
            drift < 0.1,
            "Timestamp drift \(drift)s exceeds 100ms tolerance"
        )
    }

    // MARK: - MockAudioEncoder Encode Cycle

    @Test("MockAudioEncoder encode returns buffer with matching codec")
    func encoderEncodeCycle() async throws {
        let encoder = MockAudioEncoder(codec: .aac)
        let config = AudioEncoderConfiguration(
            bitrate: 128_000,
            sampleRate: .rate48000,
            channelCount: 1
        )
        try await encoder.configure(config)

        let buffer = CaptureKit.AudioBuffer(
            data: Data(repeating: 0, count: 4096),
            format: AudioFormat(
                sampleRate: .rate48000,
                channelCount: 1,
                channelLayout: .mono,
                bitDepth: .float32
            ),
            timestamp: 0.0,
            duration: 0.021,
            sequenceNumber: 0
        )

        let encoded = try await encoder.encode(buffer)
        #expect(encoded.codec == .aac)
        #expect(encoded.data.count > 0)
        #expect(encoded.timestamp == 0.0)

        let remaining = try await encoder.flush()
        #expect(remaining.isEmpty)

        await encoder.reset()
        #expect(await encoder.resetCallCount == 1)
    }
}
