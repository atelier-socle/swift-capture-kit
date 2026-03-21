// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Streaming Showcase", .tags(.showcase))
struct StreamingShowcaseTests {

    // MARK: - MockStreamingTransport

    @Test("MockStreamingTransport tracks connect/disconnect calls")
    func transportConnectDisconnect() async throws {
        let transport = MockStreamingTransport()
        #expect(await transport.isConnected == false)

        try await transport.connect()
        #expect(await transport.isConnected == true)
        #expect(await transport.connectCallCount == 1)

        try await transport.disconnect()
        #expect(await transport.isConnected == false)
        #expect(await transport.disconnectCallCount == 1)
    }

    @Test("MockStreamingTransport captures sent packets")
    func transportSentPackets() async throws {
        let transport = MockStreamingTransport()
        try await transport.connect()

        let audioBuffer = EncodedAudioBuffer(
            data: Data([0x01, 0x02]),
            codec: .aac,
            timestamp: 0.0,
            duration: 0.021,
            sequenceNumber: 0
        )
        try await transport.send(.audio(audioBuffer))
        #expect(await transport.sentPackets.count == 1)
    }

    @Test("MockStreamingTransport captures sent configurations")
    func transportSentConfigurations() async throws {
        let transport = MockStreamingTransport()
        try await transport.connect()

        let config = StreamConfiguration.audio(
            codec: .aac, configData: Data([0xFF])
        )
        try await transport.sendConfiguration(config)
        #expect(await transport.sentConfigurations.count == 1)
    }

    @Test("MockStreamingTransport throws on connect when configured")
    func transportThrowsOnConnect() async {
        let transport = MockStreamingTransport()
        await transport.setThrowOnConnect(true)
        await #expect(throws: (any Error).self) {
            try await transport.connect()
        }
    }

    @Test("MockStreamingTransport throws on send when configured")
    func transportThrowsOnSend() async throws {
        let transport = MockStreamingTransport()
        try await transport.connect()
        await transport.setThrowOnSend(true)

        let packet = MediaPacket.audio(
            EncodedAudioBuffer(
                data: Data([0x01]),
                codec: .aac,
                timestamp: 0.0,
                duration: 0.021,
                sequenceNumber: 0
            )
        )
        await #expect(throws: (any Error).self) {
            try await transport.send(packet)
        }
    }

    // MARK: - MediaPacket

    @Test("MediaPacket.audio exposes correct timestamp")
    func mediaPacketAudioTimestamp() {
        let buffer = EncodedAudioBuffer(
            data: Data([0x01]),
            codec: .aac,
            timestamp: 1.5,
            duration: 0.021,
            sequenceNumber: 0
        )
        let packet = MediaPacket.audio(buffer)
        #expect(packet.timestamp == 1.5)
    }

    @Test("MediaPacket.video exposes correct timestamp")
    func mediaPacketVideoTimestamp() {
        let frame = EncodedVideoFrame(
            data: Data([0x00, 0x00, 0x01]),
            codec: .h264,
            timestamp: 2.0,
            isKeyFrame: true,
            sequenceNumber: 0
        )
        let packet = MediaPacket.video(frame)
        #expect(packet.timestamp == 2.0)
    }

    @Test("MediaPacket withTimestamp creates updated packet")
    func mediaPacketWithTimestamp() {
        let buffer = EncodedAudioBuffer(
            data: Data([0x01]),
            codec: .aac,
            timestamp: 0.0,
            duration: 0.021,
            sequenceNumber: 0
        )
        let packet = MediaPacket.audio(buffer)
        let updated = packet.withTimestamp(3.0)
        #expect(updated.timestamp == 3.0)
        #expect(packet.timestamp == 0.0)
    }

    // MARK: - StreamConfiguration

    @Test("StreamConfiguration.video holds codec and parameter sets")
    func streamConfigVideo() {
        let sps = Data([0x67, 0x42, 0x00, 0x1E])
        let config = StreamConfiguration.video(
            codec: .h264, parameterSets: sps
        )
        if case .video(let codec, let data) = config {
            #expect(codec == .h264)
            #expect(data == sps)
        } else {
            Issue.record("Expected video configuration")
        }
    }

    @Test("StreamConfiguration.audio holds codec and config data")
    func streamConfigAudio() {
        let asc = Data([0x12, 0x10])
        let config = StreamConfiguration.audio(
            codec: .aac, configData: asc
        )
        if case .audio(let codec, let data) = config {
            #expect(codec == .aac)
            #expect(data == asc)
        } else {
            Issue.record("Expected audio configuration")
        }
    }

    // MARK: - StreamingStats

    @Test("StreamingStats default values are zero")
    func streamingStatsDefaults() {
        let stats = StreamingStats()
        #expect(stats.bytesSent == 0)
        #expect(stats.duration == 0)
        #expect(stats.videoFPS == 0)
        #expect(stats.audioSampleRate == 0)
        #expect(stats.videoFramesDropped == 0)
        #expect(stats.audioBuffersDropped == 0)
        #expect(stats.isStreaming == false)
    }

    @Test("StreamingStats accepts custom values")
    func streamingStatsCustom() {
        let stats = StreamingStats(
            bytesSent: 1_000_000,
            duration: 60.0,
            videoFPS: 30.0,
            audioSampleRate: 48_000,
            videoFramesDropped: 2,
            audioBuffersDropped: 1,
            isStreaming: true
        )
        #expect(stats.bytesSent == 1_000_000)
        #expect(stats.duration == 60.0)
        #expect(stats.isStreaming == true)
    }
}

// MARK: - MockStreamingTransport Helpers

extension MockStreamingTransport {
    func setThrowOnSend(_ value: Bool) {
        shouldThrowOnSend = value
    }
}
