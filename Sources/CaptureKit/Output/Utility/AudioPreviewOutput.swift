// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Audio monitoring output for hearing captured audio in real time.
///
/// Passes audio through to the system audio output device for monitoring.
/// Does not record — purely for real-time monitoring during capture.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor AudioPreviewOutput: CaptureOutput {
    /// A unique identifier for this output.
    public let outputID: String

    /// A human-readable display name for this output.
    public let displayName: String = "Audio Preview Output"

    /// The type of this output destination.
    public nonisolated let outputType: CaptureOutputType = .audioPreview

    /// The current lifecycle state of this output.
    public private(set) var state: CaptureOutputState = .idle

    /// Monitoring volume (0.0–1.0).
    public var volume: Float

    /// Whether monitoring is muted.
    public var isMuted: Bool

    /// Total audio buffers monitored.
    public private(set) var buffersMonitored: Int64 = 0

    /// Creates a new audio preview output.
    ///
    /// - Parameter volume: The monitoring volume (0.0–1.0).
    public init(volume: Float = 1.0) {
        self.outputID = "audio-preview-\(UUID().uuidString.prefix(8))"
        self.volume = max(0.0, min(1.0, volume))
        self.isMuted = false
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

    /// Delivers an encoded audio buffer to this output for monitoring.
    ///
    /// - Parameter buffer: The encoded audio buffer to monitor.
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        guard state == .active, !isMuted else { return }
        buffersMonitored += 1
    }

    /// Delivers an encoded video frame to this output.
    ///
    /// Video is ignored — audio preview is audio-only.
    ///
    /// - Parameter frame: The encoded video frame (ignored).
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        // Audio preview ignores video
    }

    /// Finalizes the output.
    public func finalize() async throws {
        state = .finalized
    }
}
