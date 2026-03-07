// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Internal protocol abstracting video file reading (AVAssetReader).
///
/// Enables dependency injection for testing: real implementation uses
/// AVAssetReader, tests inject a mock that produces synthetic frames.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
protocol VideoFileReaderProviding: Sendable {
    /// Open a video file and return its duration.
    ///
    /// - Parameter url: The URL of the video file.
    /// - Returns: The duration of the video in seconds.
    func open(url: URL) async throws -> TimeInterval

    /// Read video frames from the file as an AsyncStream.
    ///
    /// - Parameters:
    ///   - url: The URL of the video file.
    ///   - outputFormat: The desired output configuration.
    ///   - startTime: The start time offset in seconds.
    ///   - endTime: The end time offset in seconds, or nil for end of file.
    ///   - playbackRate: The playback rate multiplier.
    ///   - loop: Whether to loop playback.
    /// - Returns: An async stream of captured video samples.
    func readFrames(
        from url: URL,
        outputFormat: VideoSourceConfiguration,
        startTime: TimeInterval,
        endTime: TimeInterval?,
        playbackRate: Double,
        loop: Bool
    ) async throws -> AsyncStream<CapturedVideoSample>

    /// Stop reading.
    func stop() async
}
