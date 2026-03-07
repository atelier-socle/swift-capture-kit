// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Delivers encoded media as CMSampleBuffer references.
///
/// Useful for integration with AVFoundation-based pipelines,
/// AVSampleBufferDisplayLayer, or other Apple media APIs.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor SampleBufferOutput: CaptureOutput {
    /// A unique identifier for this output.
    public let outputID: String

    /// A human-readable display name for this output.
    public let displayName: String = "Sample Buffer Output"

    /// The type of this output destination.
    public nonisolated let outputType: CaptureOutputType = .sampleBuffer

    /// The current lifecycle state of this output.
    public private(set) var state: CaptureOutputState = .idle

    /// Total number of buffers delivered.
    public private(set) var deliveryCount: Int64 = 0

    private let audioHandler: (@Sendable (EncodedAudioBuffer) async -> Void)?
    private let videoHandler: (@Sendable (EncodedVideoFrame) async -> Void)?

    /// Creates a new sample buffer output with optional handlers.
    ///
    /// - Parameters:
    ///   - audioHandler: A closure called for each audio sample buffer.
    ///   - videoHandler: A closure called for each video sample buffer.
    public init(
        audioHandler: (@Sendable (EncodedAudioBuffer) async -> Void)? = nil,
        videoHandler: (@Sendable (EncodedVideoFrame) async -> Void)? = nil
    ) {
        self.outputID = "sample-buffer-\(UUID().uuidString.prefix(8))"
        self.audioHandler = audioHandler
        self.videoHandler = videoHandler
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
    /// - Parameter buffer: The encoded audio buffer to receive.
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        guard state == .active else { return }
        deliveryCount += 1
        await audioHandler?(buffer)
    }

    /// Delivers an encoded video frame to this output.
    ///
    /// - Parameter frame: The encoded video frame to receive.
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        guard state == .active else { return }
        deliveryCount += 1
        await videoHandler?(frame)
    }

    /// Finalizes the output.
    public func finalize() async throws {
        state = .finalized
    }
}
