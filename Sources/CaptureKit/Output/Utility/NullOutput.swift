// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Discards all received media. The /dev/null of capture outputs.
///
/// Useful for testing, benchmarking encoder performance,
/// or when you only need the side effects of capture (e.g., metering)
/// without actually recording or streaming.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor NullOutput: CaptureOutput {
    /// A unique identifier for this output.
    public let outputID: String

    /// A human-readable display name for this output.
    public let displayName: String = "Null Output"

    /// The type of this output destination.
    public nonisolated let outputType: CaptureOutputType = .null

    /// The current lifecycle state of this output.
    public private(set) var state: CaptureOutputState = .idle

    /// Count of discarded audio buffers (for benchmarking).
    public private(set) var discardedAudioCount: Int64 = 0

    /// Count of discarded video frames (for benchmarking).
    public private(set) var discardedVideoCount: Int64 = 0

    /// Creates a new null output.
    public init() {
        self.outputID = "null-\(UUID().uuidString.prefix(8))"
    }

    /// Prepares the output to receive media data.
    ///
    /// - Parameters:
    ///   - audioFormat: The audio format to expect, or `nil` if no audio.
    ///   - videoFormat: The video format to expect, or `nil` if no video.
    public func prepare(
        audioFormat: AudioFormat?, videoFormat: VideoFormat?
    ) async throws {
        state = .active
    }

    /// Delivers an encoded audio buffer to this output (discarded).
    ///
    /// - Parameter buffer: The encoded audio buffer to discard.
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        discardedAudioCount += 1
    }

    /// Delivers an encoded video frame to this output (discarded).
    ///
    /// - Parameter frame: The encoded video frame to discard.
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        discardedVideoCount += 1
    }

    /// Finalizes the output.
    public func finalize() async throws {
        state = .finalized
    }
}
