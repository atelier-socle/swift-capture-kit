// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Parameters for reading audio samples from a file.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
struct FileReadRequest: Sendable {
    /// The URL of the audio file.
    let url: URL
    /// The desired output format.
    let outputFormat: AudioSourceConfiguration
    /// The start time offset.
    let startTime: TimeInterval
    /// The end time offset (nil = end of file).
    let endTime: TimeInterval?
    /// Playback rate multiplier.
    let playbackRate: Double
    /// Whether to loop playback.
    let loop: Bool
}

/// Internal protocol abstracting audio file reading (AVAssetReader).
///
/// Enables dependency injection for testing: real implementation uses
/// AVAssetReader, tests inject a mock that produces synthetic samples.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
protocol AudioFileReaderProviding: Sendable {
    /// Open a file and return its duration.
    ///
    /// - Parameter url: The URL of the audio file.
    /// - Returns: The duration of the audio file in seconds.
    func open(url: URL) async throws -> TimeInterval

    /// Read audio samples from the file as an AsyncStream.
    ///
    /// - Parameter request: The file read request parameters.
    /// - Returns: An AsyncStream of captured audio samples.
    func readSamples(
        _ request: FileReadRequest
    ) async throws -> AsyncStream<CapturedAudioSample>

    /// Stop reading.
    func stop() async
}
