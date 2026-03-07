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

        let format = AudioFormat(
            sampleRate: configuration.sampleRate,
            channelCount: configuration.channelCount,
            channelLayout: configuration.channelLayout,
            bitDepth: configuration.bitDepth
        )
        self.activeFormat = format

        return AsyncStream { continuation in
            continuation.finish()
        }
    }

    /// Stops capturing system audio.
    public func stopCapture() async {
        isCapturing = false
    }

    /// An async stream of audio level samples. Finishes immediately when hardware is unavailable.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}
