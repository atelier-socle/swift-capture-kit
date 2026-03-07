// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// An audio source that captures audio from a line-in input device.
///
/// Provides channel mapping and input gain control for professional
/// audio input scenarios.
@available(macOS 14.0, iOS 17.0, *)
public actor LineInSource: AudioSource {
    /// The unique identifier for this line-in source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Line In"

    /// The type of this audio source.
    public let sourceType: AudioSourceType = .lineIn

    /// The availability of this source on the current platform.
    public nonisolated var availability: SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: true,
            requiredPermissions: [.microphone]
        )
    }

    /// Whether this source is currently capturing audio.
    public private(set) var isCapturing: Bool = false

    /// The currently active audio format, if configured or capturing.
    public private(set) var activeFormat: AudioFormat?

    /// The currently selected audio input device.
    public var selectedDevice: AudioDeviceInfo

    /// A mapping from source channels to destination channels, if any.
    public var channelMapping: [Int: Int]?

    /// The input gain level, clamped to the range 0.0 to 1.0.
    public var inputGain: Float

    /// The current configuration used for line-in capture.
    private var configuration: AudioSourceConfiguration

    /// The audio capture engine (DI — defaults to real AVAudioEngine).
    private let captureEngine: any AudioCaptureProviding

    /// Audio level metering.
    private let audioMeter = AudioMeter()
    private let _audioLevelStream: AsyncStream<AudioLevelSample>
    private let _audioLevelContinuation: AsyncStream<AudioLevelSample>.Continuation

    /// The audio formats supported by this source.
    public var supportedFormats: [AudioFormat] {
        [
            AudioFormat(
                sampleRate: configuration.sampleRate,
                channelCount: configuration.channelCount,
                channelLayout: configuration.channelLayout,
                bitDepth: configuration.bitDepth
            )
        ]
    }

    /// Creates a new line-in source for the specified device.
    ///
    /// - Parameters:
    ///   - device: The audio device to capture from.
    ///   - inputGain: The initial input gain level, clamped to 0.0...1.0. Defaults to `1.0`.
    public init(device: AudioDeviceInfo, inputGain: Float = 1.0) {
        self.sourceID = "lineIn-\(UUID().uuidString.prefix(8))"
        self.selectedDevice = device
        self.channelMapping = nil
        self.inputGain = min(max(inputGain, 0.0), 1.0)
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.captureEngine = SystemAudioCaptureEngine()
    }

    /// Creates a new line-in source with an injected capture engine.
    ///
    /// - Parameters:
    ///   - device: The audio device to capture from.
    ///   - inputGain: The initial input gain level. Defaults to `1.0`.
    ///   - captureEngine: The audio capture engine to use.
    init(
        device: AudioDeviceInfo,
        inputGain: Float = 1.0,
        captureEngine: any AudioCaptureProviding
    ) {
        self.sourceID = "lineIn-\(UUID().uuidString.prefix(8))"
        self.selectedDevice = device
        self.channelMapping = nil
        self.inputGain = min(max(inputGain, 0.0), 1.0)
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.captureEngine = captureEngine
    }

    /// Configures this source with the given audio source configuration.
    ///
    /// The input gain is clamped to the range 0.0 to 1.0 during configuration.
    ///
    /// - Parameter configuration: The desired audio source configuration.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if the source is currently capturing.
    public func configure(_ configuration: AudioSourceConfiguration) async throws {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        self.inputGain = min(max(inputGain, 0.0), 1.0)
        self.configuration = configuration
        self.activeFormat = AudioFormat(
            sampleRate: configuration.sampleRate,
            channelCount: configuration.channelCount,
            channelLayout: configuration.channelLayout,
            bitDepth: configuration.bitDepth
        )
    }

    /// Starts capturing audio from the line-in device and returns an async stream of audio buffers.
    ///
    /// - Returns: An asynchronous stream of captured audio buffers.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    public func startCapture() async throws -> AsyncStream<AudioBuffer> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        isCapturing = true
        await audioMeter.start()

        let config = configuration
        let format = AudioFormat(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount,
            channelLayout: config.channelLayout,
            bitDepth: config.bitDepth
        )
        self.activeFormat = format

        let stream = try await captureEngine.startCapture(
            configuration: config,
            deviceID: selectedDevice.id
        )

        let meter = audioMeter
        let levelContinuation = _audioLevelContinuation
        let meterLevels = await meter.levels

        let forwardTask = Task {
            for await level in meterLevels {
                levelContinuation.yield(level)
            }
        }

        return AsyncStream { continuation in
            let task = Task {
                var seq: Int64 = 0
                for await sample in stream {
                    let buffer = AudioBuffer(
                        data: sample.data,
                        format: sample.format,
                        timestamp: sample.timestamp,
                        duration: config.preferredBufferDuration,
                        sequenceNumber: seq
                    )
                    continuation.yield(buffer)
                    await meter.processBuffer(buffer)
                    seq += 1
                }
                continuation.finish()
                forwardTask.cancel()
            }
            continuation.onTermination = { _ in
                task.cancel()
                forwardTask.cancel()
            }
        }
    }

    /// Stops capturing audio from the line-in device.
    public func stopCapture() async {
        await captureEngine.stopCapture()
        isCapturing = false
        await audioMeter.stop()
    }

    /// An async stream of real-time audio level samples.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        _audioLevelStream
    }
}
