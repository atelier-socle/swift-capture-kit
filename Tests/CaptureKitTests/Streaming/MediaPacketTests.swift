// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("MediaPacket", .timeLimit(.minutes(1)))
struct MediaPacketTests {

    @Test("video packet exposes frame timestamp")
    func videoPacketTimestamp() {
        let frame = EncodedVideoFrame(
            data: Data([0x00, 0x01]),
            codec: .h264,
            timestamp: 1.5,
            isKeyFrame: true,
            sequenceNumber: 1
        )
        let packet = MediaPacket.video(frame)
        #expect(packet.timestamp == 1.5)
    }

    @Test("audio packet exposes buffer timestamp")
    func audioPacketTimestamp() {
        let buffer = EncodedAudioBuffer(
            data: Data([0xAA, 0xBB]),
            codec: .aac,
            timestamp: 2.75,
            duration: 0.02,
            sequenceNumber: 10
        )
        let packet = MediaPacket.audio(buffer)
        #expect(packet.timestamp == 2.75)
    }

    @Test("video case pattern matching")
    func videoCaseMatching() {
        let frame = EncodedVideoFrame(
            data: Data([0x01]),
            codec: .hevc,
            timestamp: 0.5,
            isKeyFrame: false,
            sequenceNumber: 3
        )
        let packet = MediaPacket.video(frame)
        if case .video(let extracted) = packet {
            #expect(extracted.codec == .hevc)
            #expect(extracted.isKeyFrame == false)
            #expect(extracted.sequenceNumber == 3)
        } else {
            Issue.record("Expected .video case")
        }
    }

    @Test("audio case pattern matching")
    func audioCaseMatching() {
        let buffer = EncodedAudioBuffer(
            data: Data([0x02]),
            codec: .opus,
            timestamp: 3.0,
            duration: 0.04,
            sequenceNumber: 7,
            packetSizes: [1]
        )
        let packet = MediaPacket.audio(buffer)
        if case .audio(let extracted) = packet {
            #expect(extracted.codec == .opus)
            #expect(extracted.duration == 0.04)
            #expect(extracted.packetSizes == [1])
        } else {
            Issue.record("Expected .audio case")
        }
    }
}
