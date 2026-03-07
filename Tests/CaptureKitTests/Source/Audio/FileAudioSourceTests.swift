// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileAudioSource")
struct FileAudioSourceTests {

    @Test("has file source type")
    func hasFileSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(url: URL(fileURLWithPath: "/tmp/test.wav"))
        #expect(await source.sourceType == .file)
    }

    @Test("display name matches filename")
    func displayNameMatchesFilename() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(url: URL(fileURLWithPath: "/tmp/test.mp3"))
        #expect(await source.displayName == "test.mp3")
    }

    @Test("default playback rate is 1.0")
    func defaultPlaybackRate() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(url: URL(fileURLWithPath: "/tmp/test.wav"))
        #expect(await source.playbackRate == 1.0)
    }

    @Test("default loop is false")
    func defaultLoopIsFalse() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(url: URL(fileURLWithPath: "/tmp/test.wav"))
        #expect(await source.loop == false)
    }

    @Test("default startTime is nil")
    func defaultStartTimeIsNil() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(url: URL(fileURLWithPath: "/tmp/test.wav"))
        #expect(await source.startTime == nil)
    }

    @Test("default endTime is nil")
    func defaultEndTimeIsNil() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(url: URL(fileURLWithPath: "/tmp/test.wav"))
        #expect(await source.endTime == nil)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(url: URL(fileURLWithPath: "/tmp/test.wav"))
        let config = AudioSourceConfiguration(
            sampleRate: .rate44100,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .float32,
            preferredBufferDuration: 0.01
        )
        try await source.configure(config)
        let format = await source.activeFormat
        #expect(format != nil)
        #expect(format?.sampleRate == .rate44100)
        #expect(format?.channelCount == 2)
    }

    @Test("startCapture with nonexistent file throws sourceNotAvailable")
    func startCaptureWithNonexistentFileThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(url: URL(fileURLWithPath: "/tmp/nonexistent-audio-file-\(UUID().uuidString).wav"))
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
    }

    @Test("startTime can be set at init")
    func startTimeCanBeSetAtInit() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(
            url: URL(fileURLWithPath: "/tmp/test.wav"),
            startTime: 5.0
        )
        #expect(await source.startTime == 5.0)
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let tempPath = "/tmp/swift-capture-kit-test-\(UUID().uuidString).wav"
        FileManager.default.createFile(atPath: tempPath, contents: Data(count: 64))
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        let source = FileAudioSource(url: URL(fileURLWithPath: tempPath))
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
        await source.stopCapture()
    }

    @Test("availability is available on all platforms")
    func availabilityIsAvailable() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileAudioSource(url: URL(fileURLWithPath: "/tmp/test.wav"))
        let availability = source.availability
        #expect(availability.isAvailableOnCurrentPlatform == true)
    }
}
