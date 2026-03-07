// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

/// Mock screen capture video provider for testing without ScreenCaptureKit/ReplayKit.
@available(macOS 14.0, iOS 17.0, *)
actor MockScreenCaptureVideoProvider: ScreenCaptureVideoProviding {
    /// Synthetic video samples to emit when capture starts.
    var syntheticSamples: [CapturedVideoSample] = []

    /// Number of startCapture calls.
    var startCallCount = 0

    /// Number of stopCapture calls.
    var stopCallCount = 0

    /// The last mode passed to startCapture.
    var lastMode: ScreenCaptureMode?

    /// Whether to throw an error on startCapture.
    var shouldThrowOnStart = false

    func startCapture(
        mode: ScreenCaptureMode
    ) async throws -> AsyncStream<CapturedVideoSample> {
        startCallCount += 1
        lastMode = mode

        if shouldThrowOnStart {
            throw CaptureError.sourceNotAvailable(
                sourceType: "screenCapture",
                reason: "Mock error"
            )
        }

        let samples = syntheticSamples
        return AsyncStream { continuation in
            for sample in samples {
                continuation.yield(sample)
            }
            continuation.finish()
        }
    }

    func stopCapture() async {
        stopCallCount += 1
    }
}
