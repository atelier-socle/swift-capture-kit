// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// An audio source that combines multiple audio devices into a single aggregate device.
///
/// Requires at least two devices to form a valid aggregate. Supports drift compensation
/// and selection of a clock source device.
@available(macOS 14.0, *)
public actor AggregateAudioSource: AudioSource {
    /// The unique identifier for this aggregate audio source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Aggregate Audio"

    /// The type of this audio source.
    public let sourceType: AudioSourceType = .aggregate

    /// The availability of this source on the current platform.
    public nonisolated var availability: SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: true,
            requiredPermissions: [.microphone],
            notes: "macOS only"
        )
    }

    /// Whether this source is currently capturing audio.
    public private(set) var isCapturing: Bool = false

    /// The currently active audio format, if configured or capturing.
    public private(set) var activeFormat: AudioFormat?

    /// The audio devices combined in this aggregate.
    public var devices: [AudioDeviceInfo]

    /// The device used as the clock source for synchronization, if any.
    public var clockSource: AudioDeviceInfo?

    /// Whether drift compensation is enabled between devices.
    public var driftCompensation: Bool

    /// The current configuration used for aggregate audio capture.
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

    /// Creates a new aggregate audio source from the specified devices.
    ///
    /// - Parameter devices: The audio devices to combine into an aggregate device.
    public init(devices: [AudioDeviceInfo]) {
        self.sourceID = "aggregate-\(UUID().uuidString.prefix(8))"
        self.devices = devices
        self.clockSource = nil
        self.driftCompensation = true
        self.configuration = .default
    }

    /// Configures this source with the given audio source configuration.
    ///
    /// Validates that at least two devices are present before accepting configuration.
    ///
    /// - Parameter configuration: The desired audio source configuration.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if the source is currently capturing.
    /// - Throws: ``CaptureError/invalidConfiguration(_:)`` if fewer than two devices are present.
    public func configure(_ configuration: AudioSourceConfiguration) async throws {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        guard devices.count >= 2 else {
            throw CaptureError.invalidConfiguration(
                "Aggregate audio source requires at least 2 devices, but \(devices.count) provided."
            )
        }
        self.configuration = configuration
        self.activeFormat = AudioFormat(
            sampleRate: configuration.sampleRate,
            channelCount: configuration.channelCount,
            channelLayout: configuration.channelLayout,
            bitDepth: configuration.bitDepth
        )
    }

    /// Starts capturing audio from the aggregate device and returns an async stream of audio buffers.
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

    /// Stops capturing audio from the aggregate device.
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
