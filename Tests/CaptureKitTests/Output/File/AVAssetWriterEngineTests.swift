// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite(
    "AVAssetWriterEngine",
    .enabled(if: !TestEnvironment.isCI, "AVAssetWriter hangs without media services on CI"),
    .timeLimit(.minutes(1)))
struct AVAssetWriterEngineTests {

    @Test("prepare with video format succeeds", .tags(.hardware))
    func prepareWithVideoFormatSucceeds() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = AVAssetWriterEngine()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "test-\(UUID().uuidString.prefix(8)).mp4")
        defer { try? FileManager.default.removeItem(at: url) }

        let videoFormat = VideoFormat(
            resolution: .custom(width: 320, height: 240),
            frameRate: .fps30,
            pixelFormat: .bgra,
            colorSpace: .srgb,
            dynamicRange: .sdr
        )
        try await engine.prepare(
            url: url, container: .mp4,
            audioFormat: nil, videoFormat: videoFormat)
        try await engine.finalize()
    }

    @Test("writeVideo with BGRA data produces non-zero bytes", .tags(.hardware))
    func writeVideoWithBGRAData() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = AVAssetWriterEngine()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "test-\(UUID().uuidString.prefix(8)).mp4")
        defer { try? FileManager.default.removeItem(at: url) }

        let width = 16
        let height = 16
        let videoFormat = VideoFormat(
            resolution: .custom(width: width, height: height),
            frameRate: .fps30,
            pixelFormat: .bgra,
            colorSpace: .srgb,
            dynamicRange: .sdr
        )
        try await engine.prepare(
            url: url, container: .mp4,
            audioFormat: nil, videoFormat: videoFormat)

        let frameData = Data(
            repeating: 0x80, count: width * height * 4)
        try await engine.writeVideo(
            frameData, codec: .h264,
            timestamp: 0.0, isKeyFrame: true)

        let bytes = await engine.bytesWritten
        #expect(bytes > 0)
        try await engine.finalize()
    }

    @Test("finalize without prepare is no-op")
    func finalizeWithoutPrepare() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = AVAssetWriterEngine()
        try await engine.finalize()
    }

    @Test("bytesWritten starts at zero")
    func bytesWrittenStartsAtZero() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = AVAssetWriterEngine()
        let bytes = await engine.bytesWritten
        #expect(bytes == 0)
    }
}
