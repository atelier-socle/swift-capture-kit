// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Identifies a Bluetooth audio codec used for wireless audio transmission.
public enum BluetoothAudioCodec: String, Sendable, CaseIterable {
    /// Sub-Band Coding, the mandatory Bluetooth A2DP codec.
    case sbc

    /// Advanced Audio Coding.
    case aac

    /// Qualcomm aptX standard codec.
    case aptx

    /// Qualcomm aptX HD high-definition codec.
    case aptxHD

    /// Qualcomm aptX Adaptive codec.
    case aptxAdaptive

    /// Sony LDAC high-resolution codec.
    case ldac

    /// Low Complexity Communication Codec for Bluetooth LE Audio.
    case lc3

    /// Opus interactive audio codec.
    case opus
}

/// An audio source that captures audio from a Bluetooth audio device.
///
/// Supports selection of a preferred Bluetooth audio codec when the device
/// and system support codec negotiation.
@available(macOS 14.0, iOS 17.0, *)
public actor BluetoothAudioSource: AudioSource {
    /// The unique identifier for this Bluetooth audio source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Bluetooth Audio"

    /// The type of this audio source.
    public let sourceType: AudioSourceType = .bluetooth

    /// The availability of this source on the current platform.
    public nonisolated var availability: SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: true,
            requiredPermissions: [.bluetooth, .microphone]
        )
    }

    /// Whether this source is currently capturing audio.
    public private(set) var isCapturing: Bool = false

    /// The currently active audio format, if configured or capturing.
    public private(set) var activeFormat: AudioFormat?

    /// The currently selected Bluetooth audio device.
    public var selectedDevice: AudioDeviceInfo

    /// The preferred Bluetooth audio codec, if any.
    ///
    /// This is a **preference hint**, not a guarantee. Apple does not provide a
    /// public API to force a specific Bluetooth audio codec (AAC, SBC, aptX, etc.).
    /// The system negotiates the codec automatically based on the connected device's
    /// capabilities. Use ``activeCodec`` to query which codec the system selected.
    public var preferredCodec: BluetoothAudioCodec?

    /// The Bluetooth audio codec currently in use by the system, if known.
    ///
    /// Returns `nil` when not capturing or when the codec cannot be determined.
    /// Apple does not expose the negotiated Bluetooth codec in a public API;
    /// this property reflects the preferred codec when it matches a known system route.
    public private(set) var activeCodec: BluetoothAudioCodec?

    /// The current configuration used for Bluetooth audio capture.
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

    /// Creates a new Bluetooth audio source for the specified device.
    ///
    /// - Parameter device: The Bluetooth audio device to capture from.
    public init(device: AudioDeviceInfo) {
        self.sourceID = "bluetooth-\(UUID().uuidString.prefix(8))"
        self.selectedDevice = device
        self.preferredCodec = nil
        self.configuration = .default
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
        self.captureEngine = SystemAudioCaptureEngine()
    }

    /// Creates a new Bluetooth audio source with an injected capture engine.
    ///
    /// - Parameters:
    ///   - device: The Bluetooth audio device to capture from.
    ///   - captureEngine: The audio capture engine to use.
    init(
        device: AudioDeviceInfo,
        captureEngine: any AudioCaptureProviding
    ) {
        self.sourceID = "bluetooth-\(UUID().uuidString.prefix(8))"
        self.selectedDevice = device
        self.preferredCodec = nil
        self.configuration = .default
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

    /// Starts capturing audio from the Bluetooth device and returns an async stream of audio buffers.
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

        self.activeCodec = preferredCodec

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

    /// Stops capturing audio from the Bluetooth device.
    public func stopCapture() async {
        await captureEngine.stopCapture()
        isCapturing = false
        activeCodec = nil
        await audioMeter.stop()
    }

    /// An async stream of real-time audio level samples.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        _audioLevelStream
    }
}
