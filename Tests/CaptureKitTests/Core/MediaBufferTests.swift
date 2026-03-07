// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("MediaBuffer")
struct MediaBufferTests {

    @Test("AudioBuffer init and properties")
    func audioBufferInit() {
        let data = Data([0x01, 0x02, 0x03])
        let format = AudioFormat(sampleRate: .rate48000, channelCount: 2)
        let buffer = AudioBuffer(
            data: data,
            format: format,
            timestamp: 1.5,
            duration: 0.02,
            sequenceNumber: 42
        )
        #expect(buffer.data == data)
        #expect(buffer.format == format)
        #expect(buffer.timestamp == 1.5)
        #expect(buffer.duration == 0.02)
        #expect(buffer.sequenceNumber == 42)
    }

    @Test("VideoFrame init and properties")
    func videoFrameInit() {
        let data = Data([0xFF, 0xFE])
        let format = VideoFormat(resolution: .p1080, frameRate: .fps30)
        let frame = VideoFrame(
            data: data,
            format: format,
            timestamp: 2.0,
            isKeyFrame: true,
            sequenceNumber: 100
        )
        #expect(frame.data == data)
        #expect(frame.format == format)
        #expect(frame.timestamp == 2.0)
        #expect(frame.isKeyFrame == true)
        #expect(frame.sequenceNumber == 100)
    }

    @Test("EncodedAudioBuffer init and properties")
    func encodedAudioBufferInit() {
        let data = Data([0xAA, 0xBB])
        let buffer = EncodedAudioBuffer(
            data: data,
            codec: .aac,
            timestamp: 3.0,
            duration: 0.02,
            sequenceNumber: 7
        )
        #expect(buffer.data == data)
        #expect(buffer.codec == .aac)
        #expect(buffer.timestamp == 3.0)
        #expect(buffer.duration == 0.02)
        #expect(buffer.sequenceNumber == 7)
    }

    @Test("EncodedVideoFrame init and properties")
    func encodedVideoFrameInit() {
        let data = Data([0xCC, 0xDD])
        let frame = EncodedVideoFrame(
            data: data,
            codec: .hevc,
            timestamp: 4.0,
            isKeyFrame: false,
            sequenceNumber: 200
        )
        #expect(frame.data == data)
        #expect(frame.codec == .hevc)
        #expect(frame.timestamp == 4.0)
        #expect(frame.isKeyFrame == false)
        #expect(frame.sequenceNumber == 200)
    }

    @Test("AudioCodec CaseIterable count is six")
    func audioCodecCaseCount() {
        #expect(AudioCodec.allCases.count == 6)
    }

    @Test("VideoCodec CaseIterable count is six")
    func videoCodecCaseCount() {
        #expect(VideoCodec.allCases.count == 6)
    }

    @Test("AudioCodec rawValues match expected strings")
    func audioCodecRawValues() {
        #expect(AudioCodec.aac.rawValue == "aac")
        #expect(AudioCodec.alac.rawValue == "alac")
        #expect(AudioCodec.opus.rawValue == "opus")
        #expect(AudioCodec.flac.rawValue == "flac")
        #expect(AudioCodec.pcm.rawValue == "pcm")
        #expect(AudioCodec.mp3.rawValue == "mp3")
    }

    @Test("VideoCodec rawValues match expected strings")
    func videoCodecRawValues() {
        #expect(VideoCodec.h264.rawValue == "h264")
        #expect(VideoCodec.hevc.rawValue == "hevc")
        #expect(VideoCodec.prores.rawValue == "prores")
        #expect(VideoCodec.av1.rawValue == "av1")
        #expect(VideoCodec.mvHevc.rawValue == "mvHevc")
        #expect(VideoCodec.jpeg.rawValue == "jpeg")
    }
}
