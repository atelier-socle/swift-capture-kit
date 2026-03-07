// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Delivers raw pixel buffers for computer vision and ML processing.
///
/// Useful for CoreML, Vision framework, or custom image processing.
/// Delivers EncodedVideoFrame data that can be converted to CVPixelBuffer.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor PixelBufferOutput: CaptureOutput {
    /// A unique identifier for this output.
    public let outputID: String

    /// A human-readable display name for this output.
    public let displayName: String = "Pixel Buffer Output"

    /// The type of this output destination.
    public nonisolated let outputType: CaptureOutputType = .pixelBuffer

    /// The current lifecycle state of this output.
    public private(set) var state: CaptureOutputState = .idle

    /// Total number of frames delivered.
    public private(set) var deliveryCount: Int64 = 0

    private let handler: @Sendable (EncodedVideoFrame) async -> Void

    /// Creates a new pixel buffer output with a video frame handler.
    ///
    /// - Parameter handler: A closure called for each video frame.
    public init(
        handler: @Sendable @escaping (EncodedVideoFrame) async -> Void
    ) {
        self.outputID = "pixel-buffer-\(UUID().uuidString.prefix(8))"
        self.handler = handler
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
    /// Audio is ignored — pixel buffer output is video-only.
    ///
    /// - Parameter buffer: The encoded audio buffer (ignored).
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        // Pixel buffer output is video-only
    }

    /// Delivers an encoded video frame to this output.
    ///
    /// - Parameter frame: The encoded video frame to receive.
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        guard state == .active else { return }
        deliveryCount += 1
        await handler(frame)
    }

    /// Finalizes the output.
    public func finalize() async throws {
        state = .finalized
    }
}
