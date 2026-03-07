// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Video preview output for SwiftUI integration.
///
/// Receives video frames and makes them available for display
/// via a SwiftUI-compatible preview layer.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor PreviewOutput: CaptureOutput {
    /// A unique identifier for this output.
    public let outputID: String

    /// A human-readable display name for this output.
    public let displayName: String = "Preview Output"

    /// The type of this output destination.
    public nonisolated let outputType: CaptureOutputType = .preview

    /// The current lifecycle state of this output.
    public private(set) var state: CaptureOutputState = .idle

    /// The most recent video frame (for display).
    public private(set) var latestFrame: EncodedVideoFrame?

    /// Total frames received.
    public private(set) var framesReceived: Int64 = 0

    /// Whether to drop frames when the display can't keep up.
    public var dropFramesWhenBehind: Bool

    /// Creates a new preview output.
    ///
    /// - Parameter dropFramesWhenBehind: Whether to drop frames when behind.
    public init(dropFramesWhenBehind: Bool = true) {
        self.outputID = "preview-\(UUID().uuidString.prefix(8))"
        self.dropFramesWhenBehind = dropFramesWhenBehind
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

    /// Delivers an encoded audio buffer to this output.
    ///
    /// Audio is ignored — preview output is video-only.
    ///
    /// - Parameter buffer: The encoded audio buffer (ignored).
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        // Preview is video-only
    }

    /// Delivers an encoded video frame to this output.
    ///
    /// - Parameter frame: The encoded video frame to receive.
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        guard state == .active else { return }
        framesReceived += 1
        latestFrame = frame
    }

    /// Finalizes the output, clearing the latest frame.
    public func finalize() async throws {
        latestFrame = nil
        state = .finalized
    }
}
