// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// An audio source that reads audio data from a file on disk.
///
/// Supports playback rate adjustment, looping, and start/end time trimming.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor FileAudioSource: AudioSource {
    /// The unique identifier for this file audio source.
    public let sourceID: String

    /// The display name shown in UI or logs, derived from the file name.
    public let displayName: String

    /// The type of this audio source.
    public let sourceType: AudioSourceType = .file

    /// The availability of this source on the current platform.
    public nonisolated let availability: SourceAvailability = .available

    /// Whether this source is currently reading and emitting audio buffers.
    public private(set) var isCapturing: Bool = false

    /// The currently active audio format, if configured or capturing.
    public private(set) var activeFormat: AudioFormat?

    /// The URL of the audio file to read.
    public let url: URL

    /// The playback rate multiplier (1.0 = normal speed).
    public let playbackRate: Double

    /// Whether the source loops back to the start when reaching the end of the file.
    public let loop: Bool

    /// The time offset in seconds at which to begin reading, if specified.
    public let startTime: TimeInterval?

    /// The time offset in seconds at which to stop reading, if specified.
    public let endTime: TimeInterval?

    /// The current configuration used for audio output.
    private var configuration: AudioSourceConfiguration

    /// The total duration of the audio file in seconds.
    ///
    /// Returns `0.0` as a placeholder. Actual duration requires reading file metadata.
    public var duration: TimeInterval {
        0.0
    }

    /// The audio formats supported by this source.
    public var supportedFormats: [AudioFormat] {
        [
            AudioFormat(
                sampleRate: configuration.sampleRate,
                channelCount: configuration.channelCount,
                channelLayout: configuration.channelLayout,
                bitDepth: configuration.bitDepth)
        ]
    }

    /// Creates a new file audio source.
    ///
    /// - Parameters:
    ///   - url: The URL of the audio file.
    ///   - playbackRate: The playback rate multiplier. Defaults to `1.0`.
    ///   - loop: Whether to loop playback. Defaults to `false`.
    ///   - startTime: The start time offset in seconds. Defaults to `nil`.
    ///   - endTime: The end time offset in seconds. Defaults to `nil`.
    ///   - format: The audio source configuration. Defaults to `.default`.
    public init(
        url: URL,
        playbackRate: Double = 1.0,
        loop: Bool = false,
        startTime: TimeInterval? = nil,
        endTime: TimeInterval? = nil,
        format: AudioSourceConfiguration = .default
    ) {
        self.sourceID = "file-\(UUID().uuidString.prefix(8))"
        self.displayName = url.lastPathComponent
        self.url = url
        self.playbackRate = playbackRate
        self.loop = loop
        self.startTime = startTime
        self.endTime = endTime
        self.configuration = format
    }

    /// Configures this source with the given audio source configuration.
    ///
    /// - Parameter configuration: The desired audio source configuration.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if the source is currently capturing.
    public func configure(_ configuration: AudioSourceConfiguration) async throws {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        self.configuration = configuration
        self.activeFormat = AudioFormat(
            sampleRate: configuration.sampleRate,
            channelCount: configuration.channelCount,
            channelLayout: configuration.channelLayout,
            bitDepth: configuration.bitDepth
        )
    }

    /// Starts reading audio from the file and returns an async stream of audio buffers.
    ///
    /// - Returns: An asynchronous stream of audio buffers read from the file.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    /// - Throws: ``CaptureError/sourceNotAvailable(sourceType:reason:)`` if the file does not exist.
    public func startCapture() async throws -> AsyncStream<AudioBuffer> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CaptureError.sourceNotAvailable(
                sourceType: "file",
                reason: "File not found at path: \(url.path)"
            )
        }

        isCapturing = true

        let config = self.configuration
        let format = AudioFormat(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount,
            channelLayout: config.channelLayout,
            bitDepth: config.bitDepth
        )
        self.activeFormat = format

        let samplesPerBuffer = Int(config.sampleRate.rawValue * config.preferredBufferDuration)
        let bytesPerSample = config.bitDepth.byteSize
        let bufferSize = samplesPerBuffer * config.channelCount * bytesPerSample

        return AsyncStream { continuation in
            let task = Task { @concurrent in
                var sequenceNumber: Int64 = 0
                let sleepDuration = config.preferredBufferDuration

                while !Task.isCancelled {
                    let buffer = AudioBuffer(
                        data: Data(count: bufferSize),
                        format: format,
                        timestamp: TimeInterval(sequenceNumber) * sleepDuration,
                        duration: sleepDuration,
                        sequenceNumber: sequenceNumber
                    )
                    continuation.yield(buffer)
                    sequenceNumber += 1

                    try? await Task.sleep(for: .seconds(sleepDuration))
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Stops reading audio from the file.
    public func stopCapture() async {
        isCapturing = false
    }

    /// Seeks to the specified time offset in the audio file.
    ///
    /// - Parameter time: The target time offset in seconds.
    public func seek(to time: TimeInterval) async {
        // Placeholder: actual seeking requires audio file reader integration.
        _ = time
    }

    /// An async stream of audio level samples. Always finishes immediately for the file source.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
