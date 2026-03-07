// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileWriterProviding mock integration")
struct FileWriterProvidingTests {

    @Test("MockFileWriter tracks prepare calls")
    func mockFileWriterTracksPrepare() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let writer = MockFileWriter()
        try await writer.prepare(
            url: URL(filePath: "/tmp/test.mp4"),
            container: .mp4,
            audioFormat: nil,
            videoFormat: nil
        )
        let count = await writer.prepareCallCount
        #expect(count == 1)
    }

    @Test("MockFileWriter tracks bytes written")
    func mockFileWriterTracksBytesWritten() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let writer = MockFileWriter()
        try await writer.writeVideo(
            Data(repeating: 0, count: 200),
            codec: .h264,
            timestamp: 0,
            isKeyFrame: true
        )
        let bytes = await writer.bytesWritten
        #expect(bytes == 200)
    }

    @Test("MockFileWriter tracks audio and video write counts")
    func mockFileWriterTracksWriteCounts() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let writer = MockFileWriter()
        try await writer.writeAudio(
            Data([0]), codec: .aac, timestamp: 0, duration: 0.1)
        try await writer.writeAudio(
            Data([0]), codec: .aac, timestamp: 0.1, duration: 0.1)
        try await writer.writeVideo(
            Data([0]), codec: .h264, timestamp: 0, isKeyFrame: true)
        let audio = await writer.audioWriteCallCount
        let video = await writer.videoWriteCallCount
        #expect(audio == 2)
        #expect(video == 1)
    }

    @Test("MockFileWriter tracks finalize calls")
    func mockFileWriterTracksFinalize() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let writer = MockFileWriter()
        try await writer.finalize()
        let count = await writer.finalizeCallCount
        #expect(count == 1)
    }

    @Test("FileOutput uses injected writer for audio")
    func fileOutputUsesInjectedWriterForAudio() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let writer = MockFileWriter()
        let config = FileOutputConfiguration(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        let output = FileOutput(configuration: config, fileWriter: writer)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data(repeating: 0xAB, count: 50),
            codec: .aac, timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        let count = await writer.audioWriteCallCount
        #expect(count == 1)
    }

    @Test("FileOutput uses injected writer for video")
    func fileOutputUsesInjectedWriterForVideo() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let writer = MockFileWriter()
        let config = FileOutputConfiguration(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        let output = FileOutput(configuration: config, fileWriter: writer)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data(repeating: 0xAB, count: 75),
            codec: .h264, timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        let count = await writer.videoWriteCallCount
        #expect(count == 1)
    }

    @Test("FileOutput finalize calls writer finalize")
    func fileOutputFinalizeCallsWriterFinalize() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let writer = MockFileWriter()
        let config = FileOutputConfiguration(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        let output = FileOutput(configuration: config, fileWriter: writer)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        try await output.finalize()
        let count = await writer.finalizeCallCount
        #expect(count == 1)
    }
}
