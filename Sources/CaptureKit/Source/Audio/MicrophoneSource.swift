// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// An audio source that captures audio from a microphone input device.
///
/// Supports automatic gain control, echo cancellation, noise suppression,
/// and voice isolation for enhanced voice capture quality.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor MicrophoneSource: AudioSource {
    /// The unique identifier for this microphone source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Microphone"

    /// The type of this audio source.
    public let sourceType: AudioSourceType = .microphone

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

    /// The currently selected audio input device, if any.
    public var selectedDevice: AudioDeviceInfo?

    /// Whether automatic gain control is enabled.
    public var automaticGainControl: Bool

    /// Whether echo cancellation is enabled.
    public var echoCancellation: Bool

    /// Whether noise suppression is enabled.
    public var noiseSuppression: Bool

    /// Whether voice isolation is enabled.
    public var voiceIsolation: Bool

    /// The current configuration used for microphone capture.
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

    /// Creates a new microphone source.
    ///
    /// - Parameter device: The audio device to capture from. Defaults to `nil`,
    ///   which uses the system default input device.
    public init(device: AudioDeviceInfo? = nil) {
        self.sourceID = "microphone-\(UUID().uuidString.prefix(8))"
        self.selectedDevice = device
        self.automaticGainControl = true
        self.echoCancellation = false
        self.noiseSuppression = false
        self.voiceIsolation = false
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.captureEngine = SystemAudioCaptureEngine()
    }

    /// Creates a new microphone source with an injected capture engine.
    ///
    /// - Parameters:
    ///   - device: The audio device to capture from. Defaults to `nil`.
    ///   - captureEngine: The audio capture engine to use.
    init(
        device: AudioDeviceInfo? = nil,
        captureEngine: any AudioCaptureProviding
    ) {
        self.sourceID = "microphone-\(UUID().uuidString.prefix(8))"
        self.selectedDevice = device
        self.automaticGainControl = true
        self.echoCancellation = false
        self.noiseSuppression = false
        self.voiceIsolation = false
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.captureEngine = captureEngine
    }

    deinit {
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

    /// Starts capturing audio from the microphone and returns an async stream of audio buffers.
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
            deviceID: selectedDevice?.id
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

    /// Stops capturing audio from the microphone.
    public func stopCapture() async {
        await captureEngine.stopCapture()
        isCapturing = false
        _audioLevelContinuation.finish()
        await audioMeter.stop()
    }

    /// An async stream of real-time audio level samples.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        _audioLevelStream
    }
}
