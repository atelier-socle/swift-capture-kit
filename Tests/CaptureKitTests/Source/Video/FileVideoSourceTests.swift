// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileVideoSource")
struct FileVideoSourceTests {

    @Test("has file source type")
    func hasFileSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/nonexistent/video.mp4"))
        #expect(await source.sourceType == .file)
    }

    @Test("display name matches file name")
    func displayNameMatchesFileName() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/path/to/my_video.mp4"))
        #expect(await source.displayName == "my_video.mp4")
    }

    @Test("default playback rate is 1.0")
    func defaultPlaybackRateIs1() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/nonexistent/video.mp4"))
        #expect(await source.playbackRate == 1.0)
    }

    @Test("default loop is false")
    func defaultLoopIsFalse() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/nonexistent/video.mp4"))
        #expect(await source.loop == false)
    }

    @Test("is not capturing initially")
    func isNotCapturingInitially() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/nonexistent/video.mp4"))
        #expect(await source.isCapturing == false)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/nonexistent/video.mp4"))
        let config = VideoSourceConfiguration(
            resolution: .p720,
            frameRate: .fps30,
            pixelFormat: .bgra,
            colorSpace: .bt709,
            dynamicRange: .sdr,
            stabilization: .off,
            focusMode: .locked,
            exposureMode: .locked,
            whiteBalanceMode: .locked
        )
        try await source.configure(config)
        let format = await source.activeFormat
        #expect(format != nil)
        #expect(format?.resolution == .p720)
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        // Create a temporary file so startCapture succeeds
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_video_\(UUID().uuidString).mp4")
        FileManager.default.createFile(atPath: tempURL.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let source = FileVideoSource(url: tempURL, fileReader: MockVideoFileReader())
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
        await source.stopCapture()
    }

    @Test("startCapture with nonexistent file throws")
    func startCaptureWithNonexistentFileThrows() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/nonexistent/video.mp4"))
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        // Create a temporary file so startCapture succeeds
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_video_\(UUID().uuidString).mp4")
        FileManager.default.createFile(atPath: tempURL.path, contents: Data())
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let source = FileVideoSource(url: tempURL, fileReader: MockVideoFileReader())
        _ = try await source.startCapture()
        await source.stopCapture()
        #expect(await source.isCapturing == false)
    }

    @Test("seek updates startTime")
    func seekUpdatesStartTime() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/nonexistent/video.mp4"))
        #expect(await source.startTime == 0)
        try await source.seek(to: 5.0)
        #expect(await source.startTime == 5.0)
    }

    @Test("playback rate can be changed")
    func playbackRateCanBeChanged() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/nonexistent/video.mp4"))
        await source.setPlaybackRate(2.0)
        #expect(await source.playbackRate == 2.0)
    }

    @Test("availability is available on all platforms")
    func availabilityIsAvailable() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = FileVideoSource(url: URL(fileURLWithPath: "/nonexistent/video.mp4"))
        let availability = source.availability
        #expect(availability.isAvailableOnCurrentPlatform == true)
    }
}

// MARK: - Helper Extension

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension FileVideoSource {
    fileprivate func setPlaybackRate(_ rate: Double) {
        self.playbackRate = rate
    }
}
