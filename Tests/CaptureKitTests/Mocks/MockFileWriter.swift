// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

/// Mock file writer for testing FileOutput without real AVAssetWriter.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockFileWriter: FileWriterProviding {
    var prepareCallCount = 0
    var audioWriteCallCount = 0
    var videoWriteCallCount = 0
    var finalizeCallCount = 0
    var _bytesWritten: Int64 = 0

    var bytesWritten: Int64 { _bytesWritten }

    /// URLs passed to prepare, in order.
    var preparedURLs: [URL] = []

    func prepare(
        url: URL,
        container: FileContainer,
        audioFormat: AudioFormat?,
        videoFormat: VideoFormat?
    ) async throws {
        prepareCallCount += 1
        preparedURLs.append(url)
        _bytesWritten = 0
    }

    func writeAudio(
        _ data: Data,
        codec: AudioCodec,
        timestamp: TimeInterval,
        duration: TimeInterval
    ) async throws {
        audioWriteCallCount += 1
        _bytesWritten += Int64(data.count)
    }

    func writeVideo(
        _ data: Data,
        codec: VideoCodec,
        timestamp: TimeInterval,
        isKeyFrame: Bool
    ) async throws {
        videoWriteCallCount += 1
        _bytesWritten += Int64(data.count)
    }

    func finalize() async throws {
        finalizeCallCount += 1
    }
}
