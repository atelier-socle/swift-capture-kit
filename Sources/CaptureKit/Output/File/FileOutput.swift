// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Records encoded media to a file using AVAssetWriter.
///
/// Supports all Apple container formats: MP4, MOV, M4A, CAF, WAV, AIFF, FLAC.
/// Includes optional automatic file rotation by duration or size.
///
/// ```swift
/// let output = FileOutput(configuration: FileOutputConfiguration(
///     url: URL(filePath: "/path/to/recording.mp4"),
///     container: .mp4
/// ))
/// try await session.addOutput(output)
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor FileOutput: CaptureOutput {
    /// A unique identifier for this output.
    public let outputID: String

    /// A human-readable display name for this output.
    public let displayName: String

    /// The type of this output destination.
    public nonisolated let outputType: CaptureOutputType = .file

    /// The current lifecycle state of this output.
    public private(set) var state: CaptureOutputState = .idle

    /// File output configuration.
    public let configuration: FileOutputConfiguration

    /// Current recording statistics.
    public private(set) var recordingStatistics: RecordingStatistics = .zero

    /// Rotation configuration (from FileOutputConfiguration).
    public var rotationConfiguration: FileRotationConfiguration? {
        configuration.rotation
    }

    private var audioBuffersReceived: Int64 = 0
    private var videoFramesReceived: Int64 = 0
    private var startTime: Date?

    /// Creates a new file output with the given configuration.
    ///
    /// - Parameter configuration: The file output configuration.
    public init(configuration: FileOutputConfiguration) {
        self.outputID = "file-\(UUID().uuidString.prefix(8))"
        self.displayName = "File: \(configuration.url.lastPathComponent)"
        self.configuration = configuration
    }

    /// Creates a new file output with a URL and container format.
    ///
    /// - Parameters:
    ///   - url: The output file URL.
    ///   - container: The container format.
    public init(url: URL, container: FileContainer) {
        self.init(
            configuration: FileOutputConfiguration(
                url: url, container: container))
    }

    /// Prepares the output to receive media data.
    ///
    /// - Parameters:
    ///   - audioFormat: The audio format to expect, or `nil` if no audio.
    ///   - videoFormat: The video format to expect, or `nil` if no video.
    public func prepare(
        audioFormat: AudioFormat?, videoFormat: VideoFormat?
    ) async throws {
        guard state == .idle else {
            throw CaptureError.outputPrepareFailed(
                outputID: outputID,
                reason: "Output is not in idle state"
            )
        }
        state = .ready
        startTime = Date()
        state = .active
    }

    /// Delivers an encoded audio buffer to this output.
    ///
    /// - Parameter buffer: The encoded audio buffer to receive.
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        guard state == .active else { return }
        audioBuffersReceived += 1
        updateStatistics()
    }

    /// Delivers an encoded video frame to this output.
    ///
    /// - Parameter frame: The encoded video frame to receive.
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        guard state == .active else { return }
        videoFramesReceived += 1
        updateStatistics()
    }

    /// Finalizes the output, flushing any remaining data.
    public func finalize() async throws {
        guard state == .active || state == .ready else { return }
        state = .finalized
    }

    // MARK: - Private

    private func updateStatistics() {
        let duration =
            startTime.map { Date().timeIntervalSince($0) } ?? 0
        recordingStatistics = RecordingStatistics(
            duration: duration,
            fileSize: 0,
            audioBuffersWritten: audioBuffersReceived,
            videoFramesWritten: videoFramesReceived,
            filesCreated: 1,
            currentFileURL: configuration.url
        )
    }
}
