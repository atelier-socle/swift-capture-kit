// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Configuration for automatic file rotation.
public struct FileRotationConfiguration: Sendable, Equatable {
    /// Rotation trigger.
    public var trigger: FileRotationTrigger

    /// Maximum number of rotated files to keep (nil = unlimited).
    public var maxFiles: Int?

    /// Naming pattern for rotated files.
    public var namingPattern: FileRotationNaming

    /// Creates a file rotation configuration.
    ///
    /// - Parameters:
    ///   - trigger: The rotation trigger.
    ///   - maxFiles: Maximum number of rotated files to keep.
    ///   - namingPattern: The naming pattern for rotated files.
    public init(
        trigger: FileRotationTrigger,
        maxFiles: Int? = nil,
        namingPattern: FileRotationNaming = .timestamp
    ) {
        self.trigger = trigger
        self.maxFiles = maxFiles
        self.namingPattern = namingPattern
    }

    /// Creates a rotation configuration triggered by duration.
    ///
    /// - Parameters:
    ///   - seconds: The duration in seconds after which to rotate.
    ///   - maxFiles: Maximum number of rotated files to keep.
    /// - Returns: A file rotation configuration.
    public static func byDuration(
        _ seconds: TimeInterval, maxFiles: Int? = nil
    ) -> FileRotationConfiguration {
        FileRotationConfiguration(
            trigger: .duration(seconds), maxFiles: maxFiles)
    }

    /// Creates a rotation configuration triggered by file size.
    ///
    /// - Parameters:
    ///   - bytes: The file size in bytes after which to rotate.
    ///   - maxFiles: Maximum number of rotated files to keep.
    /// - Returns: A file rotation configuration.
    public static func bySize(
        _ bytes: Int64, maxFiles: Int? = nil
    ) -> FileRotationConfiguration {
        FileRotationConfiguration(
            trigger: .size(bytes), maxFiles: maxFiles)
    }
}

/// What triggers a file rotation.
public enum FileRotationTrigger: Sendable, Equatable {
    /// Rotate after a specific duration (seconds).
    case duration(TimeInterval)
    /// Rotate after reaching a specific file size (bytes).
    case size(Int64)
    /// Rotate on both duration and size (whichever comes first).
    case durationOrSize(duration: TimeInterval, size: Int64)
}

/// How rotated files are named.
public enum FileRotationNaming: String, Sendable, CaseIterable {
    /// Append ISO 8601 timestamp: `recording-2026-03-07T14-30-00.mp4`
    case timestamp
    /// Append sequential number: `recording-001.mp4`, `recording-002.mp4`
    case sequential
    /// Append Unix timestamp: `recording-1709827800.mp4`
    case unixTimestamp
}
