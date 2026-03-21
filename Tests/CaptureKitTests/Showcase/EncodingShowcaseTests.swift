// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Encoding Showcase", .tags(.showcase))
struct EncodingShowcaseTests {

    // MARK: - Audio Codec Types

    @Test("AudioCodec enumerates all supported codecs")
    func audioCodecCases() {
        let codecs = AudioCodec.allCases
        #expect(codecs.contains(.aac))
        #expect(codecs.contains(.alac))
        #expect(codecs.contains(.opus))
        #expect(codecs.contains(.flac))
        #expect(codecs.contains(.pcm))
        #expect(codecs.contains(.mp3))
    }

    @Test("VideoCodec enumerates all supported codecs")
    func videoCodecCases() {
        let codecs = VideoCodec.allCases
        #expect(codecs.contains(.h264))
        #expect(codecs.contains(.hevc))
        #expect(codecs.contains(.prores))
        #expect(codecs.contains(.av1))
        #expect(codecs.contains(.mvHevc))
    }

    // MARK: - MockAudioEncoder

    @Test("Configure AAC encoder with standard settings")
    func configureAACEncoder() async throws {
        let encoder = MockAudioEncoder(codec: .aac)
        let config = AudioEncoderConfiguration(
            bitrate: 128_000,
            sampleRate: .rate48000,
            channelCount: 2
        )
        try await encoder.configure(config)
        #expect(await encoder.configureCallCount == 1)
    }

    @Test("Encode audio buffer produces encoded output")
    func encodeAudioBuffer() async throws {
        let encoder = MockAudioEncoder(codec: .aac)
        let config = AudioEncoderConfiguration(
            bitrate: 128_000,
            sampleRate: .rate48000,
            channelCount: 1
        )
        try await encoder.configure(config)

        let buffer = AudioBuffer(
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
        #expect(await encoder.encodeCallCount == 1)
    }

    @Test("Flush encoder returns remaining frames")
    func flushEncoder() async throws {
        let encoder = MockAudioEncoder()
        let remaining = try await encoder.flush()
        #expect(remaining.isEmpty)
        #expect(await encoder.flushCallCount == 1)
    }

    @Test("Reset encoder clears state")
    func resetEncoder() async throws {
        let encoder = MockAudioEncoder()
        let config = AudioEncoderConfiguration(
            bitrate: 128_000,
            sampleRate: .rate48000,
            channelCount: 1
        )
        try await encoder.configure(config)
        await encoder.reset()
        #expect(await encoder.resetCallCount == 1)
    }

    // MARK: - MockVideoEncoder

    @Test("Configure H.264 encoder for 720p streaming")
    func configureH264Encoder() async throws {
        let encoder = MockVideoEncoder(codec: .h264)
        let config = VideoEncoderConfiguration(
            bitrate: 2_500_000,
            resolution: .p720,
            frameRate: .fps30,
            keyFrameInterval: 60,
            realTime: true
        )
        try await encoder.configure(config)
        #expect(await encoder.configureCallCount == 1)
        #expect(encoder.codec == .h264)
    }

    @Test("Encode video frame preserves key frame flag")
    func encodeVideoFrame() async throws {
        let encoder = MockVideoEncoder(codec: .h264)
        try await encoder.configure(
            VideoEncoderConfiguration(
                bitrate: 2_500_000,
                resolution: .p720,
                frameRate: .fps30,
                keyFrameInterval: 60,
                realTime: true
            ))

        let frame = VideoFrame(
            data: Data(repeating: 0, count: 1280 * 720 * 4),
            format: VideoFormat(
                resolution: .p720,
                frameRate: .fps30,
                pixelFormat: .bgra,
                colorSpace: .bt709,
                dynamicRange: .sdr
            ),
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 0
        )
        let encoded = try await encoder.encode(frame)
        #expect(encoded.isKeyFrame == true)
        #expect(encoded.codec == .h264)
        #expect(encoded.timestamp == 0.0)
    }

    @Test("Force key frame on video encoder")
    func forceKeyFrame() async throws {
        let encoder = MockVideoEncoder()
        try await encoder.forceKeyFrame()
        #expect(await encoder.forceKeyFrameCallCount == 1)
    }

    @Test("Update bitrate dynamically")
    func updateBitrate() async throws {
        let encoder = MockVideoEncoder()
        try await encoder.updateBitrate(5_000_000)
        #expect(await encoder.updateBitrateCallCount == 1)
    }

    // MARK: - EncodedAudioBuffer

    @Test("EncodedAudioBuffer with packet sizes for VBR codec")
    func encodedBufferWithPacketSizes() {
        let frame1 = Data(repeating: 0xAA, count: 768)
        let frame2 = Data(repeating: 0xBB, count: 770)
        var data = Data()
        data.append(frame1)
        data.append(frame2)

        let buffer = EncodedAudioBuffer(
            data: data,
            codec: .aac,
            timestamp: 0.0,
            duration: 0.042,
            sequenceNumber: 0,
            packetSizes: [768, 770]
        )
        #expect(buffer.packetSizes?.count == 2)
        #expect(buffer.data.count == 1538)
    }

    @Test("EncodedAudioBuffer withTimestamp preserves all fields")
    func encodedBufferWithTimestamp() {
        let buffer = EncodedAudioBuffer(
            data: Data([0x01]),
            codec: .aac,
            timestamp: 0.0,
            duration: 0.021,
            sequenceNumber: 5,
            packetSizes: [1]
        )
        let updated = buffer.withTimestamp(2.5)
        #expect(updated.timestamp == 2.5)
        #expect(updated.codec == .aac)
        #expect(updated.sequenceNumber == 5)
        #expect(updated.packetSizes == [1])
    }

    // MARK: - Encoder Protocol Properties

    @Test("Audio encoder exposes supported configuration ranges")
    func audioEncoderCapabilities() async {
        let encoder = MockAudioEncoder(
            codec: .aac,
            supportedSampleRates: [.rate44100, .rate48000],
            supportedChannelCounts: [1, 2],
            supportedBitRates: 64_000...320_000
        )
        #expect(encoder.supportedSampleRates.contains(.rate48000))
        #expect(encoder.supportedChannelCounts.contains(2))
        #expect(encoder.supportedBitRates.contains(128_000))
        #expect(encoder.isHardwareAccelerated == false)
    }

    @Test("Video encoder exposes supported configuration ranges")
    func videoEncoderCapabilities() async {
        let encoder = MockVideoEncoder(
            codec: .hevc,
            supportedResolutions: [.p720, .p1080, .uhd4K],
            supportedFrameRates: [.fps30, .fps60],
            supportedBitRates: 1_000_000...20_000_000,
            supportedProfiles: ["main", "main10"]
        )
        #expect(encoder.codec == .hevc)
        #expect(encoder.supportedResolutions.contains(.uhd4K))
        #expect(encoder.supportedProfiles.contains("main10"))
    }
}
