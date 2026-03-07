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
    public var voiceProcessingEnabled: Bool

    /// Whether voice isolation is enabled to suppress background noise.
    public var voiceIsolationEnabled: Bool

    /// The current configuration used for VoIP audio capture.
    private var configuration: AudioSourceConfiguration

    /// The audio capture engine (DI — defaults to real AVAudioEngine).
    private let captureEngine: any AudioCaptureProviding

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
                    seq += 1
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Stops capturing VoIP audio.
    public func stopCapture() async {
        await captureEngine.stopCapture()
        isCapturing = false
    }

    /// An async stream of audio level samples. Finishes immediately when hardware is unavailable.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
