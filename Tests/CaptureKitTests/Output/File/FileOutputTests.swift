// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileOutput")
struct FileOutputTests {

    @Test("has file output type")
    func hasFileOutputType() async {
        let output = FileOutput(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        #expect(output.outputType == .file)
    }

    @Test("generates unique output ID")
    func generatesUniqueOutputID() async {
        let a = FileOutput(
            url: URL(filePath: "/tmp/a.mp4"), container: .mp4)
        let b = FileOutput(
            url: URL(filePath: "/tmp/b.mp4"), container: .mp4)
        let idA = await a.outputID
        let idB = await b.outputID
        #expect(idA != idB)
        #expect(idA.hasPrefix("file-"))
    }

    @Test("display name includes filename")
    func displayNameIncludesFilename() async {
        let output = FileOutput(
            url: URL(filePath: "/tmp/recording.mp4"), container: .mp4)
        let name = await output.displayName
        #expect(name.contains("recording.mp4"))
    }

    @Test("starts in idle state")
    func startsInIdleState() async {
        let output = FileOutput(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        #expect(await output.state == .idle)
    }

    @Test("prepare transitions to active state")
    func prepareTransitionsToActive() async throws {
        let output = FileOutput(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        #expect(await output.state == .active)
    }

    @Test("prepare when not idle throws")
    func prepareWhenNotIdleThrows() async throws {
        let output = FileOutput(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        await #expect(throws: CaptureError.self) {
            try await output.prepare(audioFormat: nil, videoFormat: nil)
        }
    }

    @Test("receiveAudio increments buffer count")
    func receiveAudioIncrementsCount() async throws {
        let output = FileOutput(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        let stats = await output.recordingStatistics
        #expect(stats.audioBuffersWritten == 1)
    }

    @Test("receiveVideo increments frame count")
    func receiveVideoIncrementsCount() async throws {
        let output = FileOutput(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        let stats = await output.recordingStatistics
        #expect(stats.videoFramesWritten == 1)
    }

    @Test("receiveAudio when not active is no-op")
    func receiveAudioWhenNotActiveIsNoOp() async throws {
        let output = FileOutput(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        let stats = await output.recordingStatistics
        #expect(stats.audioBuffersWritten == 0)
    }

    @Test("finalize transitions to finalized state")
    func finalizeTransitionsToFinalized() async throws {
        let output = FileOutput(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        try await output.finalize()
        #expect(await output.state == .finalized)
    }

    @Test("recording statistics update on receive")
    func statisticsUpdateOnReceive() async throws {
        let url = URL(filePath: "/tmp/test.mp4")
        let output = FileOutput(url: url, container: .mp4)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        try await output.receiveAudio(buffer)
        let stats = await output.recordingStatistics
        #expect(stats.audioBuffersWritten == 2)
        #expect(stats.filesCreated == 1)
        #expect(stats.currentFileURL == url)
    }

    @Test("convenience init with URL and container")
    func convenienceInit() async {
        let url = URL(filePath: "/tmp/test.mov")
        let output = FileOutput(url: url, container: .mov)
        let config = await output.configuration
        #expect(config.url == url)
        #expect(config.container == .mov)
    }

    @Test("rotationConfiguration from configuration")
    func rotationConfiguration() async {
        let rotation = FileRotationConfiguration.byDuration(60)
        let config = FileOutputConfiguration(
            url: URL(filePath: "/tmp/test.mp4"),
            container: .mp4,
            rotation: rotation
        )
        let output = FileOutput(configuration: config)
        let rc = await output.rotationConfiguration
        #expect(rc == rotation)
    }
}
