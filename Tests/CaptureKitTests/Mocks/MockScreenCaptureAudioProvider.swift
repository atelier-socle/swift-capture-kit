// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

/// Mock screen capture audio provider for testing without ScreenCaptureKit.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockScreenCaptureAudioProvider: ScreenCaptureAudioProviding {
    /// Synthetic samples to emit when capture starts.
    var syntheticSamples: [CapturedAudioSample] = []

    /// Number of startCapture calls.
    var startCallCount = 0

    /// Number of stopCapture calls.
    var stopCallCount = 0

    /// The last capture mode passed.
    var lastMode: SystemAudioCaptureMode?

    /// The last excludeOwnApp value passed.
    var lastExcludeOwnApp: Bool?

    func startCapture(
        mode: SystemAudioCaptureMode,
        excludeOwnApp: Bool
    ) async throws -> AsyncStream<CapturedAudioSample> {
        startCallCount += 1
        lastMode = mode
        lastExcludeOwnApp = excludeOwnApp

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
