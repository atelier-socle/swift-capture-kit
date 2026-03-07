// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Defines how system audio is captured.
public enum SystemAudioCaptureMode: Sendable, Equatable {
    /// Captures audio from all running applications.
    case allApps

    /// Captures audio only from the specified application bundle identifiers.
    case specificApps([String])

    /// Captures audio from all applications except the specified bundle identifiers.
    case excludeApps([String])
}

/// Captures system audio on macOS using ScreenCaptureKit.
///
/// Provides control over which applications are included or excluded
/// from the system audio capture stream.
@available(macOS 14.0, *)
public actor SystemAudioSource: AudioSource {
    /// The unique identifier for this system audio source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "System Audio"

    /// The type of this audio source.
    public let sourceType: AudioSourceType = .systemAudio

    /// The availability of this source on the current platform.
    public nonisolated var availability: SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: true,
            requiredPermissions: [.screenRecording],
            notes: "macOS only — uses ScreenCaptureKit"
        )
    }

    /// Whether this source is currently capturing audio.
    public private(set) var isCapturing: Bool = false

    /// The currently active audio format, if configured or capturing.
    public private(set) var activeFormat: AudioFormat?

    /// The capture mode controlling which applications are included.
    public var captureMode: SystemAudioCaptureMode

    /// Whether to exclude audio from the current application.
    public var excludeOwnApp: Bool

    /// The current configuration used for system audio capture.
    private var configuration: AudioSourceConfiguration

    /// The screen capture audio provider (DI — defaults to real SCStream).
    private let audioProvider: any ScreenCaptureAudioProviding

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

    /// Creates a new system audio source.
    ///
    /// - Parameter mode: The capture mode. Defaults to `.allApps`.
    public init(mode: SystemAudioCaptureMode = .allApps) {
        self.sourceID = "systemAudio-\(UUID().uuidString.prefix(8))"
        self.captureMode = mode
        self.excludeOwnApp = true
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        #if canImport(ScreenCaptureKit)
            self.audioProvider = SCStreamAudioProvider()
        #else
            self.audioProvider = NoOpScreenCaptureAudioProvider()
        #endif
    }

    /// Creates a new system audio source with an injected audio provider.
    ///
    /// - Parameters:
    ///   - mode: The capture mode. Defaults to `.allApps`.
    ///   - audioProvider: The screen capture audio provider to use.
    init(
        mode: SystemAudioCaptureMode = .allApps,
        audioProvider: any ScreenCaptureAudioProviding
    ) {
        self.sourceID = "systemAudio-\(UUID().uuidString.prefix(8))"
        self.captureMode = mode
        self.excludeOwnApp = true
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.audioProvider = audioProvider
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

    /// Starts capturing system audio and returns an async stream of audio buffers.
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

        let stream = try await audioProvider.startCapture(
            mode: captureMode,
            excludeOwnApp: excludeOwnApp
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

    /// Stops capturing system audio.
    public func stopCapture() async {
        await audioProvider.stopCapture()
        isCapturing = false
        await audioMeter.stop()
    }

    /// An async stream of real-time audio level samples.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        _audioLevelStream
    }
}
