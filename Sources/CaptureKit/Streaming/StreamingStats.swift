// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// A snapshot of streaming pipeline statistics.
public struct StreamingStats: Sendable {

    /// Total bytes sent to the transport.
    public let bytesSent: Int64

    /// Elapsed time since the pipeline started.
    public let duration: TimeInterval

    /// Current video frames-per-second throughput.
    public let videoFPS: Double

    /// Current audio sample rate throughput.
    public let audioSampleRate: Double

    /// Number of video frames dropped (backpressure / slow encode).
    public let videoFramesDropped: Int64

    /// Number of audio buffers dropped.
    public let audioBuffersDropped: Int64

    /// Whether the pipeline is currently streaming.
    public let isStreaming: Bool

    public init(
        bytesSent: Int64 = 0,
        duration: TimeInterval = 0,
        videoFPS: Double = 0,
        audioSampleRate: Double = 0,
        videoFramesDropped: Int64 = 0,
        audioBuffersDropped: Int64 = 0,
        isStreaming: Bool = false
    ) {
        self.bytesSent = bytesSent
        self.duration = duration
        self.videoFPS = videoFPS
        self.audioSampleRate = audioSampleRate
        self.videoFramesDropped = videoFramesDropped
        self.audioBuffersDropped = audioBuffersDropped
        self.isStreaming = isStreaming
    }
}
