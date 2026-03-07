// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Video quality preset for broadcast extension (must be memory-conscious).
public enum BroadcastVideoQuality: String, Sendable, CaseIterable {
    /// Low quality — minimal memory usage (~720p).
    case low

    /// Medium quality — balanced (~1080p).
    case medium

    /// High quality — maximum fidelity (~1080p high bitrate).
    case high
}

/// Configuration for iOS/iPadOS Broadcast Upload Extension capture.
public struct BroadcastConfiguration: Sendable, Equatable {
    /// App Group identifier shared between main app and extension.
    public let appGroupID: String

    /// Maximum buffer size in bytes for IPC (default 5MB).
    /// Extension process has 50MB memory limit — keep this conservative.
    public var maxBufferSize: Int

    /// Whether to capture system audio from the extension.
    public var capturesSystemAudio: Bool

    /// Whether to capture microphone audio from the extension.
    public var capturesMicrophone: Bool

    /// Video quality for the extension capture.
    public var videoQuality: BroadcastVideoQuality

    /// Creates a new broadcast configuration.
    ///
    /// - Parameters:
    ///   - appGroupID: The App Group identifier.
    ///   - maxBufferSize: Maximum buffer size in bytes. Defaults to 5MB.
    ///   - capturesSystemAudio: Whether to capture system audio. Defaults to `true`.
    ///   - capturesMicrophone: Whether to capture microphone audio. Defaults to `false`.
    ///   - videoQuality: The video quality preset. Defaults to `.medium`.
    public init(
        appGroupID: String,
        maxBufferSize: Int = 5_242_880,
        capturesSystemAudio: Bool = true,
        capturesMicrophone: Bool = false,
        videoQuality: BroadcastVideoQuality = .medium
    ) {
        self.appGroupID = appGroupID
        self.maxBufferSize = maxBufferSize
        self.capturesSystemAudio = capturesSystemAudio
        self.capturesMicrophone = capturesMicrophone
        self.videoQuality = videoQuality
    }
}
