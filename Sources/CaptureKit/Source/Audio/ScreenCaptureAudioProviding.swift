// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Internal protocol abstracting ScreenCaptureKit audio capture (macOS only).
///
/// Used by SystemAudioSource to capture system audio output.
@available(macOS 14.0, *)
protocol ScreenCaptureAudioProviding: Sendable {
    /// Start capturing system audio.
    ///
    /// - Parameters:
    ///   - mode: The capture mode (all apps, specific, exclude).
    ///   - excludeOwnApp: Whether to exclude the current app's audio.
    /// - Returns: An AsyncStream of captured audio samples.
    func startCapture(
        mode: SystemAudioCaptureMode,
        excludeOwnApp: Bool
    ) async throws -> AsyncStream<CapturedAudioSample>

    /// Stop capturing.
    func stopCapture() async
}

/// No-op provider for platforms without ScreenCaptureKit.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
struct NoOpScreenCaptureAudioProvider: ScreenCaptureAudioProviding {
    func startCapture(
        mode: SystemAudioCaptureMode,
        excludeOwnApp: Bool
    ) async throws -> AsyncStream<CapturedAudioSample> {
        throw CaptureError.sourceNotAvailable(
            sourceType: "systemAudio",
            reason: "ScreenCaptureKit not available on this platform"
        )
    }

    func stopCapture() async {}
}
