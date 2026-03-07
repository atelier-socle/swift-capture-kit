// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileVideoSource with DI")
struct FileVideoSourceIntegrationTests {

    private func makeSample(
        timestamp: TimeInterval = 0.0
    ) -> CapturedVideoSample {
        CapturedVideoSample(
            data: Data(repeating: 0xCD, count: 1280 * 720 * 4),
            timestamp: timestamp,
            format: VideoFormat(
                resolution: .p720,
                frameRate: .fps30,
                pixelFormat: .bgra,
                colorSpace: .bt709,
                dynamicRange: .sdr
            ),
            isKeyFrame: true
        )
    }

    private func makeTempFile() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_video_\(UUID().uuidString).mp4")
        FileManager.default.createFile(atPath: url.path, contents: Data([0x00]))
        return url
    }

    @Test("startCapture calls reader open and readFrames")
    func startCaptureCallsReader() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let reader = MockVideoFileReader()
        let url = makeTempFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let source = FileVideoSource(url: url, fileReader: reader)
        _ = try await source.startCapture()
        let openCount = await reader.openCallCount
        let readCount = await reader.readCallCount
        #expect(openCount == 1)
        #expect(readCount == 1)
    }

    @Test("produces VideoFrame from CapturedVideoSample")
    func producesVideoFrame() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let reader = MockVideoFileReader()
        let sample = makeSample(timestamp: 2.5)
        await reader.setSamples([sample])
        let url = makeTempFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let source = FileVideoSource(url: url, fileReader: reader)
        let stream = try await source.startCapture()
        var frames: [VideoFrame] = []
        for await frame in stream {
            frames.append(frame)
        }
        #expect(frames.count == 1)
        #expect(frames[0].timestamp == 2.5)
    }

    @Test("stopCapture calls reader stop")
    func stopCaptureCallsReaderStop() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let reader = MockVideoFileReader()
        let url = makeTempFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let source = FileVideoSource(url: url, fileReader: reader)
        _ = try await source.startCapture()
        await source.stopCapture()
        let count = await reader.stopCallCount
        #expect(count == 1)
    }

    @Test("fileDuration set after startCapture")
    func fileDurationSetAfterStart() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let reader = MockVideoFileReader()
        await reader.setDuration(42.0)
        let url = makeTempFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let source = FileVideoSource(url: url, fileReader: reader)
        _ = try await source.startCapture()
        let duration = await source.fileDuration
        #expect(duration == 42.0)
    }

    @Test("sequential frames have incrementing sequence numbers")
    func sequentialFramesIncrementSequence() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let reader = MockVideoFileReader()
        await reader.setSamples([
            makeSample(timestamp: 0.0),
            makeSample(timestamp: 0.033)
        ])
        let url = makeTempFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let source = FileVideoSource(url: url, fileReader: reader)
        let stream = try await source.startCapture()
        var seqs: [Int64] = []
        for await frame in stream {
            seqs.append(frame.sequenceNumber)
        }
        #expect(seqs == [0, 1])
    }

    @Test("nonexistent file throws sourceNotAvailable")
    func nonexistentFileThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let reader = MockVideoFileReader()
        let source = FileVideoSource(
            url: URL(fileURLWithPath: "/nonexistent/video.mp4"),
            fileReader: reader
        )
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
    }

    @Test("seek updates startTime before capture")
    func seekUpdatesStartTime() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let reader = MockVideoFileReader()
        let source = FileVideoSource(
            url: URL(fileURLWithPath: "/nonexistent/video.mp4"),
            fileReader: reader
        )
        try await source.seek(to: 10.0)
        let st = await source.startTime
        #expect(st == 10.0)
    }

    @Test("reader open error propagates")
    func readerOpenErrorPropagates() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let reader = MockVideoFileReader()
        await reader.setThrowOnOpen(true)
        let url = makeTempFile()
        defer { try? FileManager.default.removeItem(at: url) }
        let source = FileVideoSource(url: url, fileReader: reader)
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
    }
}

// MARK: - MockVideoFileReader helpers

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension MockVideoFileReader {
    func setSamples(_ samples: [CapturedVideoSample]) {
        self.syntheticSamples = samples
    }

    func setDuration(_ duration: TimeInterval) {
        self.mockDuration = duration
    }

    func setThrowOnOpen(_ value: Bool) {
        self.shouldThrowOnOpen = value
    }
}
