// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// An audio source that generates silent audio buffers filled with zeros.
///
/// Useful for testing pipelines, placeholder streams, or muting scenarios
/// where a valid audio stream is required but no actual audio content is needed.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor SilenceSource: AudioSource {
    /// The unique identifier for this silence source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Silence Generator"

    /// The type of this audio source.
    public let sourceType: AudioSourceType = .generator

    /// The availability of this source on the current platform.
    public nonisolated let availability: SourceAvailability = .available

    /// Whether this source is currently generating silence buffers.
    public private(set) var isCapturing: Bool = false

    /// The currently active audio format, if configured or capturing.
    public private(set) var activeFormat: AudioFormat?

    /// The current configuration used for silence generation.
    private var configuration: AudioSourceConfiguration

    /// Audio level metering.
    private let audioMeter = AudioMeter()
    private let _audioLevelStream: AsyncStream<AudioLevelSample>
    private let _audioLevelContinuation: AsyncStream<AudioLevelSample>.Continuation

    /// The active stream continuation, stored so stopCapture() can finish it.
    private var _streamContinuation: AsyncStream<AudioBuffer>.Continuation?

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

    /// Creates a new silence source with the given format configuration.
    ///
    /// - Parameter format: The audio source configuration. Defaults to `.default`.
    public init(format: AudioSourceConfiguration = .default) {
        self.sourceID = "silence-\(UUID().uuidString.prefix(8))"
        self.configuration = format
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
    }

    deinit {
        _streamContinuation?.finish()
        _audioLevelContinuation.finish()
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

    /// Starts generating silent audio buffers and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of zero-filled audio buffers.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    public func startCapture() async throws -> AsyncStream<AudioBuffer> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        isCapturing = true
        await audioMeter.start()

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

        let meter = audioMeter
        let levelContinuation = _audioLevelContinuation
        let meterLevels = await meter.levels

        let forwardTask = Task {
            for await level in meterLevels {
                levelContinuation.yield(level)
            }
        }

        let (stream, continuation) = AsyncStream.makeStream(of: AudioBuffer.self)
        _streamContinuation = continuation

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
                await meter.processBuffer(buffer)
                sequenceNumber += 1

                try? await Task.sleep(for: .seconds(sleepDuration))
            }
            continuation.finish()
            forwardTask.cancel()
        }

        continuation.onTermination = { _ in
            task.cancel()
            forwardTask.cancel()
        }

        return stream
    }

    /// Stops generating silent audio buffers.
    public func stopCapture() async {
        isCapturing = false
        _streamContinuation?.finish()
        _streamContinuation = nil
        _audioLevelContinuation.finish()
        await audioMeter.stop()
    }

    /// An async stream of real-time audio level samples.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        _audioLevelStream
    }
}
