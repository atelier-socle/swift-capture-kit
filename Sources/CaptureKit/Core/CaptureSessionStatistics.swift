// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// A snapshot of capture session performance metrics at a point in time.
public struct CaptureSessionStatistics: Sendable, Equatable {
    /// The total time the session has been running, in seconds.
    public let uptime: TimeInterval

    /// The total number of audio buffers processed since the session started.
    public let audioBuffersProcessed: Int64

    /// The total number of video frames processed since the session started.
    public let videoFramesProcessed: Int64

    /// The total number of video frames dropped since the session started.
    public let videoFramesDropped: Int64

    /// The total number of encoded audio bytes produced since the session started.
    public let audioBytesEncoded: Int64

    /// The total number of encoded video bytes produced since the session started.
    public let videoBytesEncoded: Int64

    /// The current audio encoding bitrate in bits per second.
    public let currentAudioBitrate: Double

    /// The current video encoding bitrate in bits per second.
    public let currentVideoBitrate: Double

    /// The current video frame rate in frames per second.
    public let currentFrameRate: Double

    /// The current CPU usage as a percentage (0.0 to 100.0).
    public let cpuUsage: Double

    /// The current memory usage in bytes.
    public let memoryUsage: Int64

    /// A statistics snapshot where all values are zero.
    public static let zero = CaptureSessionStatistics(
        uptime: 0,
        audioBuffersProcessed: 0,
        videoFramesProcessed: 0,
        videoFramesDropped: 0,
        audioBytesEncoded: 0,
        videoBytesEncoded: 0,
        currentAudioBitrate: 0,
        currentVideoBitrate: 0,
        currentFrameRate: 0,
        cpuUsage: 0,
        memoryUsage: 0
    )

    /// Creates a new statistics snapshot.
    ///
    /// - Parameters:
    ///   - uptime: The session uptime in seconds.
    ///   - audioBuffersProcessed: The total audio buffers processed.
    ///   - videoFramesProcessed: The total video frames processed.
    ///   - videoFramesDropped: The total video frames dropped.
    ///   - audioBytesEncoded: The total encoded audio bytes.
    ///   - videoBytesEncoded: The total encoded video bytes.
    ///   - currentAudioBitrate: The current audio bitrate in bits per second.
    ///   - currentVideoBitrate: The current video bitrate in bits per second.
    ///   - currentFrameRate: The current frame rate in frames per second.
    ///   - cpuUsage: The current CPU usage percentage.
    ///   - memoryUsage: The current memory usage in bytes.
    public init(
        uptime: TimeInterval,
        audioBuffersProcessed: Int64,
        videoFramesProcessed: Int64,
        videoFramesDropped: Int64,
        audioBytesEncoded: Int64,
        videoBytesEncoded: Int64,
        currentAudioBitrate: Double,
        currentVideoBitrate: Double,
        currentFrameRate: Double,
        cpuUsage: Double,
        memoryUsage: Int64
    ) {
        self.uptime = uptime
        self.audioBuffersProcessed = audioBuffersProcessed
        self.videoFramesProcessed = videoFramesProcessed
        self.videoFramesDropped = videoFramesDropped
        self.audioBytesEncoded = audioBytesEncoded
        self.videoBytesEncoded = videoBytesEncoded
        self.currentAudioBitrate = currentAudioBitrate
        self.currentVideoBitrate = currentVideoBitrate
        self.currentFrameRate = currentFrameRate
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
    }
}
