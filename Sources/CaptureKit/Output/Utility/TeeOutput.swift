// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Fan-out output that delivers media to multiple child outputs.
///
/// Useful for simultaneously recording + streaming + previewing.
///
/// ```swift
/// let tee = TeeOutput(outputs: [fileOutput, streamingOutput, previewOutput])
/// try await session.addOutput(tee)
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor TeeOutput: CaptureOutput {
    /// A unique identifier for this output.
    public let outputID: String

    /// A human-readable display name for this output.
    public let displayName: String = "Tee Output"

    /// The type of this output destination.
    public nonisolated let outputType: CaptureOutputType = .tee

    /// The current lifecycle state of this output.
    public private(set) var state: CaptureOutputState = .idle

    /// Number of child outputs.
    public var childCount: Int { children.count }

    private var children: [any CaptureOutput]

    /// Creates a new tee output with the given child outputs.
    ///
    /// - Parameter outputs: The child outputs to fan-out to.
    public init(outputs: [any CaptureOutput]) {
        self.outputID = "tee-\(UUID().uuidString.prefix(8))"
        self.children = outputs
    }

    /// Prepares the output and all children to receive media data.
    ///
    /// - Parameters:
    ///   - audioFormat: The audio format to expect, or `nil` if no audio.
    ///   - videoFormat: The video format to expect, or `nil` if no video.
    public func prepare(
        audioFormat: AudioFormat?, videoFormat: VideoFormat?
    ) async throws {
        for child in children {
            try await child.prepare(
                audioFormat: audioFormat, videoFormat: videoFormat)
        }
        state = .active
    }

    /// Delivers an encoded audio buffer to all child outputs.
    ///
    /// - Parameter buffer: The encoded audio buffer to receive.
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        guard state == .active else { return }
        for child in children {
            try await child.receiveAudio(buffer)
        }
    }

    /// Delivers an encoded video frame to all child outputs.
    ///
    /// - Parameter frame: The encoded video frame to receive.
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        guard state == .active else { return }
        for child in children {
            try await child.receiveVideo(frame)
        }
    }

    /// Finalizes all child outputs.
    public func finalize() async throws {
        for child in children {
            try await child.finalize()
        }
        state = .finalized
    }

    /// Adds a child output.
    ///
    /// - Parameter output: The child output to add.
    public func addChild(_ output: any CaptureOutput) {
        children.append(output)
    }

    /// Removes a child output by ID.
    ///
    /// - Parameter outputID: The ID of the child output to remove.
    public func removeChild(_ outputID: String) {
        children.removeAll { $0.outputID == outputID }
    }
}
