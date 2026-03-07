// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Statistics for an active file recording.
public struct RecordingStatistics: Sendable, Equatable {
    /// Duration of the current recording segment (seconds).
    public let duration: TimeInterval
    /// Current file size in bytes.
    public let fileSize: Int64
    /// Number of audio buffers written.
    public let audioBuffersWritten: Int64
    /// Number of video frames written.
    public let videoFramesWritten: Int64
    /// Number of files created (including rotations).
    public let filesCreated: Int
    /// Current file URL.
    public let currentFileURL: URL?

    /// Creates recording statistics.
    ///
    /// - Parameters:
    ///   - duration: Duration of the current recording segment.
    ///   - fileSize: Current file size in bytes.
    ///   - audioBuffersWritten: Number of audio buffers written.
    ///   - videoFramesWritten: Number of video frames written.
    ///   - filesCreated: Number of files created.
    ///   - currentFileURL: The current file URL.
    public init(
        duration: TimeInterval = 0,
        fileSize: Int64 = 0,
        audioBuffersWritten: Int64 = 0,
        videoFramesWritten: Int64 = 0,
        filesCreated: Int = 0,
        currentFileURL: URL? = nil
    ) {
        self.duration = duration
        self.fileSize = fileSize
        self.audioBuffersWritten = audioBuffersWritten
        self.videoFramesWritten = videoFramesWritten
        self.filesCreated = filesCreated
        self.currentFileURL = currentFileURL
    }

    /// Zero statistics.
    public static let zero = RecordingStatistics()
}
