// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Identifies the type of a capture output destination.
public enum CaptureOutputType: String, Sendable, CaseIterable {
    /// Output to a file on disk.
    case file

    /// Output to a streaming destination.
    case streaming

    /// Output via a callback closure.
    case callback

    /// Output as sample buffers.
    case sampleBuffer

    /// Output as pixel buffers.
    case pixelBuffer

    /// Output to a preview display.
    case preview

    /// Output to an audio preview monitor.
    case audioPreview

    /// A null output that discards all data.
    case null

    /// A tee output that duplicates data to multiple destinations.
    case tee
}

/// Represents the lifecycle state of a capture output.
public enum CaptureOutputState: String, Sendable, CaseIterable {
    /// The output is idle and not yet configured.
    case idle

    /// The output is preparing for use.
    case preparing

    /// The output is ready to receive data.
    case ready

    /// The output is actively receiving and processing data.
    case active

    /// The output is paused.
    case paused

    /// The output has encountered an error.
    case error

    /// The output has been finalized and is no longer usable.
    case finalized
}

/// Protocol for capture output destinations that receive encoded media data.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public protocol CaptureOutput: Sendable {
    /// A unique identifier for this output.
    var outputID: String { get }

    /// A human-readable display name for this output.
    var displayName: String { get }

    /// The type of this output destination.
    var outputType: CaptureOutputType { get }

    /// The current lifecycle state of this output.
    var state: CaptureOutputState { get async }

    /// Prepares the output to receive media data in the specified formats.
    ///
    /// - Parameters:
    ///   - audioFormat: The audio format to expect, or `nil` if no audio.
    ///   - videoFormat: The video format to expect, or `nil` if no video.
    func prepare(audioFormat: AudioFormat?, videoFormat: VideoFormat?) async throws

    /// Delivers an encoded audio buffer to this output.
    ///
    /// - Parameter buffer: The encoded audio buffer to receive.
    func receiveAudio(_ buffer: EncodedAudioBuffer) async throws

    /// Delivers an encoded video frame to this output.
    ///
    /// - Parameter frame: The encoded video frame to receive.
    func receiveVideo(_ frame: EncodedVideoFrame) async throws

    /// Finalizes the output, flushing any remaining data and releasing resources.
    func finalize() async throws
}
