// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for macOS ScreenCaptureKit capture.
public struct ScreenCaptureKitConfiguration: Sendable, Equatable {
    /// Whether to show the cursor in the capture.
    public var showsCursor: Bool

    /// Whether to capture system audio along with video.
    public var capturesSystemAudio: Bool

    /// Whether to capture microphone audio (macOS 15+).
    public var capturesMicrophone: Bool

    /// Whether to exclude the current app from capture.
    public var excludeOwnApp: Bool

    /// Scale factor for Retina displays (1 = logical, 2 = retina).
    public var scaleFactor: Int

    /// Whether to capture in HDR (macOS 14+).
    public var captureHDR: Bool

    /// Presenter overlay mode (macOS 14+ — show webcam overlay).
    public var presenterOverlay: Bool

    /// Creates a new ScreenCaptureKit configuration.
    ///
    /// - Parameters:
    ///   - showsCursor: Whether to show the cursor. Defaults to `true`.
    ///   - capturesSystemAudio: Whether to capture system audio. Defaults to `false`.
    ///   - capturesMicrophone: Whether to capture microphone audio. Defaults to `false`.
    ///   - excludeOwnApp: Whether to exclude the current app. Defaults to `true`.
    ///   - scaleFactor: The scale factor. Defaults to `2`.
    ///   - captureHDR: Whether to capture in HDR. Defaults to `false`.
    ///   - presenterOverlay: Whether to enable presenter overlay. Defaults to `false`.
    public init(
        showsCursor: Bool = true,
        capturesSystemAudio: Bool = false,
        capturesMicrophone: Bool = false,
        excludeOwnApp: Bool = true,
        scaleFactor: Int = 2,
        captureHDR: Bool = false,
        presenterOverlay: Bool = false
    ) {
        self.showsCursor = showsCursor
        self.capturesSystemAudio = capturesSystemAudio
        self.capturesMicrophone = capturesMicrophone
        self.excludeOwnApp = excludeOwnApp
        self.scaleFactor = scaleFactor
        self.captureHDR = captureHDR
        self.presenterOverlay = presenterOverlay
    }

    /// Default configuration for screen recording.
    public static let `default` = ScreenCaptureKitConfiguration()

    /// Configuration optimized for streaming (lower resolution, includes audio).
    public static let streaming = ScreenCaptureKitConfiguration(
        showsCursor: true,
        capturesSystemAudio: true,
        capturesMicrophone: false,
        excludeOwnApp: true,
        scaleFactor: 1,
        captureHDR: false,
        presenterOverlay: false
    )

    /// Configuration for tutorial recording (cursor visible, mic on).
    public static let tutorial = ScreenCaptureKitConfiguration(
        showsCursor: true,
        capturesSystemAudio: true,
        capturesMicrophone: true,
        excludeOwnApp: true,
        scaleFactor: 2,
        captureHDR: false,
        presenterOverlay: false
    )
}
