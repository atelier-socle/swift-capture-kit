// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for iOS/iPadOS ReplayKit in-app recording.
public struct ReplayKitConfiguration: Sendable, Equatable {
    /// Whether to include microphone audio in the recording.
    public var isMicrophoneEnabled: Bool

    /// Whether to include front camera overlay.
    public var isCameraEnabled: Bool

    /// Whether to capture in HDR (iOS 26+).
    public var hdrEnabled: Bool

    /// Creates a new ReplayKit configuration.
    ///
    /// - Parameters:
    ///   - isMicrophoneEnabled: Whether to include microphone audio. Defaults to `false`.
    ///   - isCameraEnabled: Whether to include front camera overlay. Defaults to `false`.
    ///   - hdrEnabled: Whether to capture in HDR. Defaults to `false`.
    public init(
        isMicrophoneEnabled: Bool = false,
        isCameraEnabled: Bool = false,
        hdrEnabled: Bool = false
    ) {
        self.isMicrophoneEnabled = isMicrophoneEnabled
        self.isCameraEnabled = isCameraEnabled
        self.hdrEnabled = hdrEnabled
    }

    /// Default configuration for in-app recording.
    public static let `default` = ReplayKitConfiguration()

    /// Configuration for gameplay recording (mic on for commentary).
    public static let gameplay = ReplayKitConfiguration(
        isMicrophoneEnabled: true,
        isCameraEnabled: false,
        hdrEnabled: false
    )

    /// Configuration for tutorial with facecam.
    public static let tutorial = ReplayKitConfiguration(
        isMicrophoneEnabled: true,
        isCameraEnabled: true,
        hdrEnabled: false
    )
}
