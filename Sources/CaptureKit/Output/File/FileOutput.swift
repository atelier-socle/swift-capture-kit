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

    private var startTime: Date?
    private let fileWriter: any FileWriterProviding
    private var filesCreated: Int = 0
    private var audioBuffersReceived: Int64 = 0
    private var videoFramesReceived: Int64 = 0

    /// Creates a new file output with the given configuration.
    ///
    /// - Parameter configuration: The file output configuration.
    public init(configuration: FileOutputConfiguration) {
        self.outputID = "file-\(UUID().uuidString.prefix(8))"
        self.displayName = "File: \(configuration.url.lastPathComponent)"
        self.configuration = configuration
        self.fileWriter = AVAssetWriterEngine()
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

    /// Creates a new file output with an injected writer (for testing).
    ///
    /// - Parameters:
    ///   - configuration: The file output configuration.
    ///   - fileWriter: The file writer provider to use.
    init(
        configuration: FileOutputConfiguration,
        fileWriter: any FileWriterProviding
    ) {
        self.outputID = "file-\(UUID().uuidString.prefix(8))"
        self.displayName = "File: \(configuration.url.lastPathComponent)"
        self.configuration = configuration
        self.fileWriter = fileWriter
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

        try await fileWriter.prepare(
            url: configuration.url,
            container: configuration.container,
            audioFormat: audioFormat,
            videoFormat: videoFormat
        )

        startTime = Date()
        filesCreated = 1
        state = .active
    }

    /// Delivers an encoded audio buffer to this output.
    ///
    /// - Parameter buffer: The encoded audio buffer to receive.
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        guard state == .active else { return }
        try await fileWriter.writeAudio(
            buffer.data,
            codec: buffer.codec,
            timestamp: buffer.timestamp,
            duration: buffer.duration
        )
        audioBuffersReceived += 1
        await updateStatistics()
        await checkRotation()
    }

    /// Delivers an encoded video frame to this output.
    ///
    /// - Parameter frame: The encoded video frame to receive.
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        guard state == .active else { return }
        try await fileWriter.writeVideo(
            frame.data,
            codec: frame.codec,
            timestamp: frame.timestamp,
            isKeyFrame: frame.isKeyFrame
        )
        videoFramesReceived += 1
        await updateStatistics()
        await checkRotation()
    }

    /// Finalizes the output, flushing any remaining data.
    public func finalize() async throws {
        guard state == .active || state == .ready else { return }
        try await fileWriter.finalize()
        await updateStatistics()
        state = .finalized
    }

    // MARK: - Private

    /// Checks if rotation is needed based on the configuration.
    ///
    /// File rotation creates new files when duration or size thresholds
    /// are reached. The old file is finalized and a new one is started.
    private func checkRotation() async {
        guard let rotation = configuration.rotation else { return }
        let duration =
            startTime.map { Date().timeIntervalSince($0) } ?? 0
        let currentSize = await fileWriter.bytesWritten

        let shouldRotate: Bool = switch rotation.trigger {
        case .duration(let maxDuration):
            duration >= maxDuration
        case .size(let maxSize):
            currentSize >= maxSize
        case .durationOrSize(let maxDuration, let maxSize):
            duration >= maxDuration || currentSize >= maxSize
        }

        if shouldRotate {
            try? await fileWriter.finalize()
            filesCreated += 1
            startTime = Date()
            let rotatedURL = Self.rotatedURL(
                base: configuration.url,
                index: filesCreated,
                naming: rotation.namingPattern
            )
            try? await fileWriter.prepare(
                url: rotatedURL,
                container: configuration.container,
                audioFormat: nil,
                videoFormat: nil
            )
        }
    }

    private static func rotatedURL(
        base: URL,
        index: Int,
        naming: FileRotationNaming
    ) -> URL {
        let ext = base.pathExtension
        let stem = base.deletingPathExtension().lastPathComponent
        let dir = base.deletingLastPathComponent()

        let suffix: String = switch naming {
        case .timestamp:
            ISO8601DateFormatter().string(from: Date())
                .replacingOccurrences(of: ":", with: "-")
        case .sequential:
            String(format: "%03d", index)
        case .unixTimestamp:
            String(Int(Date().timeIntervalSince1970))
        }

        return dir.appendingPathComponent("\(stem)-\(suffix).\(ext)")
    }

    private func updateStatistics() async {
        let duration =
            startTime.map { Date().timeIntervalSince($0) } ?? 0
        let written = await fileWriter.bytesWritten
        recordingStatistics = RecordingStatistics(
            duration: duration,
            fileSize: written,
            audioBuffersWritten: audioBuffersReceived,
            videoFramesWritten: videoFramesReceived,
            filesCreated: filesCreated,
            currentFileURL: configuration.url
        )
    }
}
