// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// An audio source optimized for Voice over IP capture scenarios.
///
/// Provides voice processing and voice isolation capabilities for
/// enhanced speech capture in communication applications.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor VoIPAudioSource: AudioSource {
    /// The unique identifier for this VoIP audio source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "VoIP Audio"

    /// The type of this audio source.
    public let sourceType: AudioSourceType = .voip

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

    /// Whether voice processing is enabled for enhanced speech capture.
    ///
    /// When `true`, enables echo cancellation and noise suppression on the
    /// AVAudioEngine input node via `setVoiceProcessingEnabled(_:)`.
    /// Applied when ``startCapture()`` is called.
    public var voiceProcessingEnabled: Bool

    /// Whether voice isolation is enabled to suppress background noise.
    ///
    /// Voice isolation further reduces non-speech audio beyond standard voice
    /// processing. Applied when ``startCapture()`` is called alongside
    /// ``voiceProcessingEnabled``.
    public var voiceIsolationEnabled: Bool

    /// The current configuration used for VoIP audio capture.
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

    /// Creates a new VoIP audio source.
    ///
    /// - Parameter voiceProcessingEnabled: Whether to enable voice processing. Defaults to `true`.
    public init(voiceProcessingEnabled: Bool = true) {
        self.sourceID = "voip-\(UUID().uuidString.prefix(8))"
        self.voiceProcessingEnabled = voiceProcessingEnabled
        self.voiceIsolationEnabled = false
        self.configuration = .voiceChat
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.captureEngine = SystemAudioCaptureEngine()
    }

    /// Creates a new VoIP audio source with an injected capture engine.
    ///
    /// - Parameters:
    ///   - voiceProcessingEnabled: Whether to enable voice processing. Defaults to `true`.
    ///   - captureEngine: The audio capture engine to use.
    init(
        voiceProcessingEnabled: Bool = true,
        captureEngine: any AudioCaptureProviding
    ) {
        self.sourceID = "voip-\(UUID().uuidString.prefix(8))"
        self.voiceProcessingEnabled = voiceProcessingEnabled
        self.voiceIsolationEnabled = false
        self.configuration = .voiceChat
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.captureEngine = captureEngine
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

    /// Starts capturing VoIP audio and returns an async stream of audio buffers.
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

        try await captureEngine.configureAudioSession(
            category: "playAndRecord",
            mode: "voiceChat"
        )

        let stream = try await captureEngine.startCapture(
            configuration: config,
            deviceID: nil
        )

        await enableVoiceProcessingIfConfigured()

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

    /// Attempts to enable voice processing; falls back gracefully if unavailable.
    private func enableVoiceProcessingIfConfigured() async {
        guard voiceProcessingEnabled else { return }
        do {
            try await captureEngine.setVoiceProcessingEnabled(true)
        } catch {
            // Voice processing may not be available on all platforms/configurations
            // (e.g. macOS may return -10849). Fall back to standard capture.
            print(
                "VoIPAudioSource: voice processing unavailable, falling back — \(error)"
            )
        }
    }

    /// Stops capturing VoIP audio.
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
