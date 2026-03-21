// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CaptureSession pipeline", .timeLimit(.minutes(1)))
struct CaptureSessionPipelineTests {

    @Test("processAudioBuffer increments statistics")
    func processAudioBufferIncrementsStats() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let session = CaptureSession()
        let buffer = AudioBuffer(
            data: Data(repeating: 0, count: 100),
            format: AudioFormat(sampleRate: .rate48000, channelCount: 1),
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 0
        )
        await session.processAudioBuffer(buffer)
        let stats = await session.statistics
        #expect(stats.audioBuffersProcessed == 1)
    }

    @Test("processVideoFrame increments statistics")
    func processVideoFrameIncrementsStats() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let session = CaptureSession()
        let frame = VideoFrame(
            data: Data(repeating: 0, count: 100),
            format: VideoFormat(
                resolution: .p1080, frameRate: .fps30,
                pixelFormat: .bgra, colorSpace: .bt709,
                dynamicRange: .sdr),
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 0
        )
        await session.processVideoFrame(frame)
        let stats = await session.statistics
        #expect(stats.videoFramesProcessed == 1)
    }

    @Test("processAudioBuffer with encoder encodes data")
    func processAudioBufferWithEncoder() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let session = CaptureSession()
        let encoder = MockAudioEncoder()
        await session.setAudioEncoderForTesting(encoder)
        let buffer = AudioBuffer(
            data: Data(repeating: 0, count: 100),
            format: AudioFormat(sampleRate: .rate48000, channelCount: 1),
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 0
        )
        await session.processAudioBuffer(buffer)
        let count = await encoder.encodeCallCount
        #expect(count == 1)
    }

    @Test("processVideoFrame with encoder encodes data")
    func processVideoFrameWithEncoder() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let session = CaptureSession()
        let encoder = MockVideoEncoder()
        await session.setVideoEncoderForTesting(encoder)
        let frame = VideoFrame(
            data: Data(repeating: 0, count: 100),
            format: VideoFormat(
                resolution: .p1080, frameRate: .fps30,
                pixelFormat: .bgra, colorSpace: .bt709,
                dynamicRange: .sdr),
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 0
        )
        await session.processVideoFrame(frame)
        let count = await encoder.encodeCallCount
        #expect(count == 1)
    }

    @Test("processAudioBuffer delivers to outputs")
    func processAudioBufferDeliversToOutputs() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let session = CaptureSession()
        let output = MockCaptureOutput()
        try await session.addOutput(output)
        let buffer = AudioBuffer(
            data: Data(repeating: 0, count: 100),
            format: AudioFormat(sampleRate: .rate48000, channelCount: 1),
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 0
        )
        await session.processAudioBuffer(buffer)
        let audioCount = await output.receiveAudioCallCount
        #expect(audioCount == 1)
    }

    @Test("processVideoFrame delivers to outputs")
    func processVideoFrameDeliversToOutputs() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let session = CaptureSession()
        let output = MockCaptureOutput()
        try await session.addOutput(output)
        let frame = VideoFrame(
            data: Data(repeating: 0, count: 100),
            format: VideoFormat(
                resolution: .p1080, frameRate: .fps30,
                pixelFormat: .bgra, colorSpace: .bt709,
                dynamicRange: .sdr),
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 0
        )
        await session.processVideoFrame(frame)
        let videoCount = await output.receiveVideoCallCount
        #expect(videoCount == 1)
    }

    @Test("updateStatistics updates uptime")
    func updateStatisticsUpdatesUptime() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let session = CaptureSession()
        await session.setStartTimeForTesting(Date().addingTimeInterval(-5.0))
        await session.updateStatistics()
        let stats = await session.statistics
        #expect(stats.uptime >= 4.5)
    }

    @Test("multiple audio buffers accumulate statistics")
    func multipleAudioBuffersAccumulate() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let session = CaptureSession()
        let buffer = AudioBuffer(
            data: Data(repeating: 0, count: 50),
            format: AudioFormat(sampleRate: .rate48000, channelCount: 1),
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 0
        )
        await session.processAudioBuffer(buffer)
        await session.processAudioBuffer(buffer)
        await session.processAudioBuffer(buffer)
        let stats = await session.statistics
        #expect(stats.audioBuffersProcessed == 3)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension CaptureSession {
    func setStartTimeForTesting(_ date: Date) {
        self.startTime = date
    }

    func setAudioEncoderForTesting(_ encoder: any AudioEncoderProtocol) {
        self.audioEncoder = encoder
    }

    func setVideoEncoderForTesting(_ encoder: any VideoEncoderProtocol) {
        self.videoEncoder = encoder
    }
}
