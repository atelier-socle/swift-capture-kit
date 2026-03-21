// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

#if os(macOS)
    import CoreAudio
#endif

/// An audio source that combines multiple audio devices into a single aggregate device.
///
/// On macOS, creates a real CoreAudio aggregate device combining all specified
/// sub-devices. The aggregate device is destroyed when capture stops.
/// On iOS, aggregate devices are not supported by CoreAudio — the source
/// falls back to using the first device.
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

    /// The audio capture engine (DI — defaults to real AVAudioEngine).
    private let captureEngine: any AudioCaptureProviding

    #if os(macOS)
        /// The CoreAudio aggregate device ID, created at capture start.
        private var aggregateDeviceID: AudioDeviceID = 0
    #endif

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

    /// Creates a new aggregate audio source from the specified devices.
    ///
    /// - Parameter devices: The audio devices to combine into an aggregate device.
    public init(devices: [AudioDeviceInfo]) {
        self.sourceID = "aggregate-\(UUID().uuidString.prefix(8))"
        self.devices = devices
        self.clockSource = nil
        self.driftCompensation = true
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.captureEngine = SystemAudioCaptureEngine()
    }

    /// Creates a new aggregate audio source with an injected capture engine.
    ///
    /// - Parameters:
    ///   - devices: The audio devices to combine.
    ///   - captureEngine: The audio capture engine to use.
    init(
        devices: [AudioDeviceInfo],
        captureEngine: any AudioCaptureProviding
    ) {
        self.sourceID = "aggregate-\(UUID().uuidString.prefix(8))"
        self.devices = devices
        self.clockSource = nil
        self.driftCompensation = true
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.captureEngine = captureEngine
    }

    deinit { _audioLevelContinuation.finish() }

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
        await audioMeter.start()

        let config = configuration
        let format = AudioFormat(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount,
            channelLayout: config.channelLayout,
            bitDepth: config.bitDepth
        )
        self.activeFormat = format

        #if os(macOS)
            aggregateDeviceID = try createAggregateDevice()
        #endif

        let deviceID: String?
        #if os(macOS)
            deviceID = String(aggregateDeviceID)
        #else
            deviceID = devices.first?.id
        #endif

        let stream = try await captureEngine.startCapture(
            configuration: config,
            deviceID: deviceID
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

    /// Stops capturing audio from the aggregate device.
    public func stopCapture() async {
        await captureEngine.stopCapture()
        #if os(macOS)
            destroyAggregateDevice()
        #endif
        isCapturing = false
        _audioLevelContinuation.finish()
        await audioMeter.stop()
    }

    /// An async stream of real-time audio level samples.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        _audioLevelStream
    }

    #if os(macOS)
        /// Creates a CoreAudio aggregate device from the configured sub-devices.
        ///
        /// Uses ``clockSource`` (or the first device if nil) as the clock master.
        /// Applies ``driftCompensation`` to all non-clock sub-devices.
        private func createAggregateDevice() throws -> AudioDeviceID {
            let uid =
                "com.atelier-socle.capturekit.aggregate-\(UUID().uuidString)"
            let clockDeviceUID = (clockSource ?? devices[0]).id

            let subDevices: [[String: Any]] = devices.map { device in
                var entry: [String: Any] = [
                    kAudioSubDeviceUIDKey as String: device.id
                ]
                if device.id != clockDeviceUID && driftCompensation {
                    entry[kAudioSubDeviceDriftCompensationKey as String] = 1
                }
                return entry
            }

            let description: [String: Any] = [
                kAudioAggregateDeviceNameKey as String:
                    "CaptureKit-Aggregate",
                kAudioAggregateDeviceUIDKey as String: uid,
                kAudioAggregateDeviceSubDeviceListKey as String: subDevices,
                kAudioAggregateDeviceMainSubDeviceKey as String:
                    clockDeviceUID,
                kAudioAggregateDeviceClockDeviceKey as String:
                    clockDeviceUID,
                kAudioAggregateDeviceIsPrivateKey as String: true,
                kAudioAggregateDeviceIsStackedKey as String: false
            ]

            var aggregateID: AudioDeviceID = 0
            let desc = description as CFDictionary

            let status = AudioHardwareCreateAggregateDevice(
                desc, &aggregateID)
            guard status == noErr else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "aggregate",
                    reason:
                        "Failed to create aggregate device (OSStatus: \(status))"
                )
            }

            return aggregateID
        }

        /// Destroys the CoreAudio aggregate device.
        private func destroyAggregateDevice() {
            guard aggregateDeviceID != 0 else { return }
            AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            aggregateDeviceID = 0
        }
    #endif
}
