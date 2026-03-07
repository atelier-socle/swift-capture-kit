// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

/// Mock video file reader for testing without real video files.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockVideoFileReader: VideoFileReaderProviding {
    /// The duration to return from open().
    var mockDuration: TimeInterval = 10.0

    /// Synthetic samples to emit when reading.
    var syntheticSamples: [CapturedVideoSample] = []

    /// Number of open() calls.
    var openCallCount = 0

    /// Number of readFrames() calls.
    var readCallCount = 0

    /// Number of stop() calls.
    var stopCallCount = 0

    /// Whether open() should throw an error.
    var shouldThrowOnOpen = false

    func open(url: URL) async throws -> TimeInterval {
        openCallCount += 1
        if shouldThrowOnOpen {
            throw CaptureError.sourceNotAvailable(
                sourceType: "file",
                reason: "Mock open error"
            )
        }
        return mockDuration
    }

    func readFrames(
        from url: URL,
        outputFormat: VideoSourceConfiguration,
        startTime: TimeInterval,
        endTime: TimeInterval?,
        playbackRate: Double,
        loop: Bool
    ) async throws -> AsyncStream<CapturedVideoSample> {
        readCallCount += 1
        let samples = syntheticSamples
        return AsyncStream { continuation in
            for sample in samples {
                continuation.yield(sample)
            }
            continuation.finish()
        }
    }

    func stop() async {
        stopCallCount += 1
    }
}
