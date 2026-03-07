// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileAudioSource with DI")
struct FileAudioSourceIntegrationTests {

    private func makeSample(
        timestamp: TimeInterval = 0.0
    ) -> CapturedAudioSample {
        CapturedAudioSample(
            data: Data(repeating: 0xAA, count: 512),
            timestamp: timestamp,
            format: AudioFormat(
                sampleRate: .rate48000,
                channelCount: 2,
                channelLayout: .stereo,
                bitDepth: .float32
            )
        )
    }

    private func makeTempFile() -> (URL, String) {
        let path =
            "/tmp/swift-capture-kit-test-\(UUID().uuidString).wav"
        FileManager.default.createFile(
            atPath: path, contents: Data(count: 64))
        return (URL(fileURLWithPath: path), path)
    }

    @Test("startCapture calls fileReader open")
    func startCaptureCallsOpen() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let (url, path) = makeTempFile()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let reader = MockAudioFileReader()
        let source = FileAudioSource(
            url: url, fileReader: reader)
        _ = try await source.startCapture()
        let count = await reader.openCallCount
        #expect(count == 1)
        await source.stopCapture()
    }

    @Test("startCapture calls fileReader readSamples")
    func startCaptureCallsReadSamples() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let (url, path) = makeTempFile()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let reader = MockAudioFileReader()
        let source = FileAudioSource(
            url: url, fileReader: reader)
        _ = try await source.startCapture()
        let count = await reader.readCallCount
        #expect(count == 1)
        await source.stopCapture()
    }

    @Test("duration is set after startCapture")
    func durationIsSet() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let (url, path) = makeTempFile()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let reader = MockAudioFileReader()
        await reader.setMockDuration(42.5)
        let source = FileAudioSource(
            url: url, fileReader: reader)
        _ = try await source.startCapture()
        let duration = await source.duration
        #expect(duration == 42.5)
        await source.stopCapture()
    }

    @Test("stopCapture calls fileReader stop")
    func stopCaptureCallsStop() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let (url, path) = makeTempFile()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let reader = MockAudioFileReader()
        let source = FileAudioSource(
            url: url, fileReader: reader)
        _ = try await source.startCapture()
        await source.stopCapture()
        let count = await reader.stopCallCount
        #expect(count == 1)
    }

    @Test("produces AudioBuffers from CapturedAudioSamples")
    func producesBuffers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let (url, path) = makeTempFile()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let reader = MockAudioFileReader()
        await reader.setSyntheticSamples([
            makeSample(timestamp: 0.0),
            makeSample(timestamp: 0.02)
        ])
        let source = FileAudioSource(
            url: url, fileReader: reader)
        let stream = try await source.startCapture()

        var buffers: [AudioBuffer] = []
        for await buffer in stream {
            buffers.append(buffer)
        }

        #expect(buffers.count == 2)
        #expect(buffers[0].sequenceNumber == 0)
        #expect(buffers[1].sequenceNumber == 1)
        await source.stopCapture()
    }

    @Test("nonexistent file throws sourceNotAvailable")
    func nonexistentFileThrows() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let reader = MockAudioFileReader()
        let source = FileAudioSource(
            url: URL(fileURLWithPath: "/tmp/no-such-file.wav"),
            fileReader: reader
        )
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
    }

    @Test("open error propagates")
    func openErrorPropagates() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let (url, path) = makeTempFile()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let reader = MockAudioFileReader()
        await reader.setShouldThrowOnOpen(true)
        let source = FileAudioSource(
            url: url, fileReader: reader)
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
    }

    @Test("loop parameter is passed through")
    func loopParameter() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let (url, path) = makeTempFile()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let reader = MockAudioFileReader()
        let source = FileAudioSource(
            url: url, loop: true, fileReader: reader)
        let loop = await source.loop
        #expect(loop == true)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension MockAudioFileReader {
    func setMockDuration(_ duration: TimeInterval) {
        self.mockDuration = duration
    }

    func setSyntheticSamples(
        _ samples: [CapturedAudioSample]
    ) {
        self.syntheticSamples = samples
    }

    func setShouldThrowOnOpen(_ value: Bool) {
        self.shouldThrowOnOpen = value
    }
}
