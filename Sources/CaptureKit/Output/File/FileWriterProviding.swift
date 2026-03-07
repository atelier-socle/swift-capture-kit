// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Internal protocol abstracting file writing (AVAssetWriter).
///
/// Enables dependency injection for testing: real implementation uses
/// AVAssetWriter, tests inject a mock that tracks calls.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
protocol FileWriterProviding: Sendable {
    /// Prepare the writer for the given container and formats.
    func prepare(
        url: URL,
        container: FileContainer,
        audioFormat: AudioFormat?,
        videoFormat: VideoFormat?
    ) async throws

    /// Write an encoded audio buffer.
    func writeAudio(
        _ data: Data,
        codec: AudioCodec,
        timestamp: TimeInterval,
        duration: TimeInterval
    ) async throws

    /// Write an encoded video frame.
    func writeVideo(
        _ data: Data,
        codec: VideoCodec,
        timestamp: TimeInterval,
        isKeyFrame: Bool
    ) async throws

    /// Finalize writing and close the file.
    func finalize() async throws

    /// Total bytes written so far.
    var bytesWritten: Int64 { get async }
}
