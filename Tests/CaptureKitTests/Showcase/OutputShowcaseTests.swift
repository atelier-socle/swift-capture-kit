// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Output Showcase", .tags(.showcase))
struct OutputShowcaseTests {

    // MARK: - CaptureOutputType

    @Test("CaptureOutputType enumerates all output types")
    func outputTypes() {
        let types = CaptureOutputType.allCases
        #expect(types.contains(.file))
        #expect(types.contains(.streaming))
        #expect(types.contains(.callback))
        #expect(types.contains(.null))
        #expect(types.contains(.tee))
    }

    // MARK: - CaptureOutputState

    @Test("CaptureOutputState has all lifecycle states")
    func outputStates() {
        let states = CaptureOutputState.allCases
        #expect(states.contains(.idle))
        #expect(states.contains(.preparing))
        #expect(states.contains(.ready))
        #expect(states.contains(.active))
        #expect(states.contains(.paused))
        #expect(states.contains(.error))
        #expect(states.contains(.finalized))
    }

    // MARK: - CallbackOutput

    @Test("CallbackOutput delivers audio to handler")
    func callbackOutputAudio() async throws {
        let output = CallbackOutput(
            audioHandler: { _ in }
        )
        let format = AudioFormat(
            sampleRate: .rate48000,
            channelCount: 1,
            channelLayout: .mono,
            bitDepth: .float32
        )
        try await output.prepare(audioFormat: format, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0x01]),
            codec: .aac,
            timestamp: 0.0,
            duration: 0.021,
            sequenceNumber: 0
        )
        try await output.receiveAudio(buffer)
        #expect(await output.audioDeliveryCount == 1)
    }

    @Test("CallbackOutput delivers video to handler")
    func callbackOutputVideo() async throws {
        let output = CallbackOutput(
            videoHandler: { _ in }
        )
        let format = VideoFormat(
            resolution: .p1080,
            frameRate: .fps30,
            pixelFormat: .bgra,
            colorSpace: .bt709,
            dynamicRange: .sdr
        )
        try await output.prepare(audioFormat: nil, videoFormat: format)
        let frame = EncodedVideoFrame(
            data: Data([0x00, 0x00, 0x01]),
            codec: .h264,
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 0
        )
        try await output.receiveVideo(frame)
        #expect(await output.videoDeliveryCount == 1)
    }

    @Test("CallbackOutput type is callback")
    func callbackOutputType() {
        let output = CallbackOutput()
        #expect(output.outputType == .callback)
    }

    // MARK: - NullOutput

    @Test("NullOutput discards audio and video")
    func nullOutputDiscards() async throws {
        let output = NullOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)

        let audioBuffer = EncodedAudioBuffer(
            data: Data([0x01]),
            codec: .aac,
            timestamp: 0.0,
            duration: 0.021,
            sequenceNumber: 0
        )
        try await output.receiveAudio(audioBuffer)
        #expect(await output.discardedAudioCount == 1)

        let videoFrame = EncodedVideoFrame(
            data: Data([0x00]),
            codec: .h264,
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 0
        )
        try await output.receiveVideo(videoFrame)
        #expect(await output.discardedVideoCount == 1)
    }

    @Test("NullOutput type is null")
    func nullOutputType() {
        let output = NullOutput()
        #expect(output.outputType == .null)
    }

    @Test("NullOutput starts in idle state")
    func nullOutputState() async {
        let output = NullOutput()
        let state = await output.state
        #expect(state == .idle)
    }

    // MARK: - FileOutputConfiguration

    @Test("FileOutputConfiguration holds all properties")
    func fileOutputConfig() {
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        let config = FileOutputConfiguration(
            url: url,
            container: .mp4,
            metadata: FileMetadata(title: "Test"),
            overwriteExisting: true
        )
        #expect(config.url == url)
        #expect(config.container == .mp4)
        #expect(config.metadata?.title == "Test")
        #expect(config.overwriteExisting == true)
        #expect(config.rotation == nil)
    }

    @Test("FileOutputConfiguration with rotation")
    func fileOutputConfigWithRotation() {
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        let rotation = FileRotationConfiguration(
            trigger: .duration(3600),
            maxFiles: 5,
            namingPattern: .sequential
        )
        let config = FileOutputConfiguration(
            url: url,
            container: .mp4,
            rotation: rotation
        )
        #expect(config.rotation?.maxFiles == 5)
        #expect(config.rotation?.namingPattern == .sequential)
    }

    // MARK: - FileContainer

    @Test("FileContainer video support")
    func fileContainerVideoSupport() {
        #expect(FileContainer.mp4.supportsVideo == true)
        #expect(FileContainer.mov.supportsVideo == true)
        #expect(FileContainer.m4a.supportsVideo == false)
        #expect(FileContainer.caf.supportsVideo == false)
        #expect(FileContainer.wav.supportsVideo == false)
        #expect(FileContainer.aiff.supportsVideo == false)
        #expect(FileContainer.flac.supportsVideo == false)
    }

    @Test("FileContainer audio support")
    func fileContainerAudioSupport() {
        for container in FileContainer.allCases {
            #expect(container.supportsAudio == true)
        }
    }

    @Test("FileContainer file extensions match raw values")
    func fileContainerExtensions() {
        #expect(FileContainer.mp4.fileExtension == "mp4")
        #expect(FileContainer.mov.fileExtension == "mov")
        #expect(FileContainer.m4a.fileExtension == "m4a")
        #expect(FileContainer.wav.fileExtension == "wav")
    }

    @Test("FileContainer supported codecs are non-empty")
    func fileContainerSupportedCodecs() {
        #expect(FileContainer.mp4.supportedAudioCodecs.contains(.aac))
        #expect(FileContainer.mp4.supportedVideoCodecs.contains(.h264))
        #expect(FileContainer.wav.supportedAudioCodecs == [.pcm])
        #expect(FileContainer.wav.supportedVideoCodecs.isEmpty)
    }

    // MARK: - FileMetadata

    @Test("FileMetadata stores all fields")
    func fileMetadata() {
        let meta = FileMetadata(
            title: "Episode 1",
            artist: "Host",
            album: "Podcast",
            comment: "First episode",
            custom: ["genre": "tech"]
        )
        #expect(meta.title == "Episode 1")
        #expect(meta.artist == "Host")
        #expect(meta.album == "Podcast")
        #expect(meta.comment == "First episode")
        #expect(meta.custom["genre"] == "tech")
    }

    // MARK: - FileRotation

    @Test("FileRotationTrigger duration")
    func rotationTriggerDuration() {
        let trigger = FileRotationTrigger.duration(3600)
        if case .duration(let seconds) = trigger {
            #expect(seconds == 3600)
        } else {
            Issue.record("Expected duration trigger")
        }
    }

    @Test("FileRotationTrigger size")
    func rotationTriggerSize() {
        let trigger = FileRotationTrigger.size(100_000_000)
        if case .size(let bytes) = trigger {
            #expect(bytes == 100_000_000)
        } else {
            Issue.record("Expected size trigger")
        }
    }

    @Test("FileRotationNaming enumerates all patterns")
    func rotationNamingPatterns() {
        let patterns = FileRotationNaming.allCases
        #expect(patterns.contains(.timestamp))
        #expect(patterns.contains(.sequential))
        #expect(patterns.contains(.unixTimestamp))
    }

    // MARK: - MockCaptureOutput

    @Test("MockCaptureOutput tracks all calls")
    func mockOutputTracking() async throws {
        let output = MockCaptureOutput()
        let format = AudioFormat(
            sampleRate: .rate48000,
            channelCount: 1,
            channelLayout: .mono,
            bitDepth: .float32
        )
        try await output.prepare(
            audioFormat: format, videoFormat: nil)
        #expect(await output.prepareCallCount == 1)

        let buffer = EncodedAudioBuffer(
            data: Data([0x01]),
            codec: .aac,
            timestamp: 0.0,
            duration: 0.021,
            sequenceNumber: 0
        )
        try await output.receiveAudio(buffer)
        #expect(await output.receiveAudioCallCount == 1)

        let audioBuffers = await output.receivedAudioBuffers
        #expect(audioBuffers.count == 1)

        try await output.finalize()
        #expect(await output.finalizeCallCount == 1)
    }

    @Test("MockCaptureOutput failure injection on prepare")
    func mockOutputFailure() async {
        let output = MockCaptureOutput()
        await output.setShouldFail(true)
        await #expect(throws: (any Error).self) {
            try await output.prepare(
                audioFormat: nil, videoFormat: nil)
        }
    }

    // MARK: - RecordingStatistics

    @Test("RecordingStatistics zero has all zeros")
    func recordingStatsZero() {
        let stats = RecordingStatistics.zero
        #expect(stats.duration == 0)
        #expect(stats.fileSize == 0)
        #expect(stats.audioBuffersWritten == 0)
        #expect(stats.videoFramesWritten == 0)
        #expect(stats.filesCreated == 0)
        #expect(stats.currentFileURL == nil)
    }
}
