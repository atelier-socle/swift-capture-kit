// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Internal protocol abstracting screen capture video (macOS ScreenCaptureKit, iOS ReplayKit).
///
/// Used by ScreenCaptureSource to capture screen content as video frames.
@available(macOS 14.0, iOS 17.0, *)
protocol ScreenCaptureVideoProviding: Sendable {
    /// Start capturing screen video.
    ///
    /// - Parameter mode: The screen capture mode.
    /// - Returns: An AsyncStream of captured video samples.
    func startCapture(
        mode: ScreenCaptureMode
    ) async throws -> AsyncStream<CapturedVideoSample>

    /// Stop capturing.
    func stopCapture() async
}

/// No-op provider for platforms without screen capture support.
@available(macOS 14.0, iOS 17.0, *)
struct NoOpScreenCaptureVideoProvider: ScreenCaptureVideoProviding {
    func startCapture(
        mode: ScreenCaptureMode
    ) async throws -> AsyncStream<CapturedVideoSample> {
        throw CaptureError.sourceNotAvailable(
            sourceType: "screenCapture",
            reason: "Screen capture not available on this platform"
        )
    }

    func stopCapture() async {}
}
