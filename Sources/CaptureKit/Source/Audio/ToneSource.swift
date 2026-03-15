// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Describes the waveform shape used by a tone generator.
public enum ToneWaveform: String, Sendable, CaseIterable {
    /// A pure sinusoidal waveform.
    case sine

    /// A square waveform alternating between +1 and -1.
    case square

    /// A sawtooth waveform ramping linearly from -1 to +1.
    case sawtooth

    /// A triangle waveform with linear ramps between -1 and +1.
    case triangle

    /// White noise with uniform random distribution.
    case whiteNoise

    /// Pink noise with reduced high-frequency energy.
    case pinkNoise

    /// Brown (Brownian) noise with a random walk characteristic.
    case brownNoise

    /// A sine wave at the EBU R 128 calibration level (-20 dBFS).
    case ebur128Calibration
}

/// An audio source that generates tonal or noise waveforms for testing and calibration.
///
/// Supports sine, square, sawtooth, triangle, white/pink/brown noise,
/// and an EBU R 128 calibration tone.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor ToneSource: AudioSource {
    /// The unique identifier for this tone source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Tone Generator"

    /// The type of this audio source.
    public let sourceType: AudioSourceType = .generator

    /// The availability of this source on the current platform.
    public nonisolated let availability: SourceAvailability = .available

    /// Whether this source is currently generating audio.
    public private(set) var isCapturing: Bool = false

    /// The currently active audio format, if configured or capturing.
    public private(set) var activeFormat: AudioFormat?

    /// The waveform shape to generate.
    public let waveform: ToneWaveform

    /// The frequency of the generated tone in hertz.
    public let frequency: Double

    /// The amplitude of the generated signal, from 0.0 (silent) to 1.0 (full scale).
    public let amplitude: Float

    /// The current configuration used for tone generation.
    private var configuration: AudioSourceConfiguration

    /// Audio level metering.
    private let audioMeter = AudioMeter()
    private let _audioLevelStream: AsyncStream<AudioLevelSample>
    private let _audioLevelContinuation: AsyncStream<AudioLevelSample>.Continuation

    /// The audio formats supported by this source.
    public var supportedFormats: [AudioFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new tone source with the specified waveform, frequency, and amplitude.
    ///
    /// - Parameters:
    ///   - waveform: The waveform shape to generate. Defaults to `.sine`.
    ///   - frequency: The frequency in hertz. Defaults to `440.0` (A4).
    ///   - amplitude: The amplitude from 0.0 to 1.0. Defaults to `0.5`.
    ///   - format: The audio source configuration. Defaults to `.default`.
    public init(
        waveform: ToneWaveform = .sine,
        frequency: Double = 440.0,
        amplitude: Float = 0.5,
        format: AudioSourceConfiguration = .default
    ) {
        self.sourceID = "tone-\(UUID().uuidString.prefix(8))"
        self.waveform = waveform
        self.frequency = frequency
        self.amplitude = amplitude
        self.configuration = format
        let (stream, continuation) = AsyncStream.makeStream(of: AudioLevelSample.self)
        self._audioLevelStream = stream
        self._audioLevelContinuation = continuation
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
        self.activeFormat = makeFormat(from: configuration)
    }

    /// Starts generating tone audio buffers and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of audio buffers containing the generated waveform.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    public func startCapture() async throws -> AsyncStream<AudioBuffer> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        isCapturing = true
        await audioMeter.start()

        let config = self.configuration
        let format = makeFormat(from: config)
        self.activeFormat = format

        let samplesPerBuffer = Int(config.sampleRate.rawValue * config.preferredBufferDuration)
        let bytesPerSample = config.bitDepth.byteSize
        let channelCount = config.channelCount
        let sampleRate = config.sampleRate.rawValue
        let waveform = self.waveform
        let frequency = self.frequency
        let amplitude = self.amplitude

        let meter = audioMeter
        let forwardTask = await startMeterForwarding(meter: meter)

        return AsyncStream { continuation in
            let task = Task { @concurrent in
                var sequenceNumber: Int64 = 0
                var globalSampleIndex: Int64 = 0
                let bufferDuration = config.preferredBufferDuration
                let startTime = ContinuousClock.now

                while !Task.isCancelled {
                    let data = ToneSource.generateBuffer(
                        waveform: waveform, frequency: frequency, amplitude: amplitude,
                        sampleRate: sampleRate, samplesPerBuffer: samplesPerBuffer,
                        channelCount: channelCount, bytesPerSample: bytesPerSample,
                        globalSampleIndex: globalSampleIndex
                    )

                    let timestamp = Double(globalSampleIndex) / sampleRate
                    let buffer = AudioBuffer(
                        data: data,
                        format: format,
                        timestamp: timestamp,
                        duration: bufferDuration,
                        sequenceNumber: sequenceNumber
                    )
                    continuation.yield(buffer)
                    await meter.processBuffer(buffer)
                    sequenceNumber += 1
                    globalSampleIndex += Int64(samplesPerBuffer)

                    // Sleep until the next buffer is due based on absolute
                    // time. This prevents cumulative drift from Task.sleep
                    // jitter and meter processing overhead.
                    let nextDue = startTime + .seconds(timestamp + bufferDuration)
                    let now = ContinuousClock.now
                    if nextDue > now {
                        try? await Task.sleep(until: nextDue, clock: .continuous)
                    }
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

    /// Stops generating tone audio buffers.
    public func stopCapture() async {
        isCapturing = false
        await audioMeter.stop()
    }

    /// An async stream of real-time audio level samples.
    public nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        _audioLevelStream
    }

    private func startMeterForwarding(meter: AudioMeter) async -> Task<Void, Never> {
        let levelContinuation = _audioLevelContinuation
        let meterLevels = await meter.levels
        return Task {
            for await level in meterLevels {
                levelContinuation.yield(level)
            }
        }
    }

    private func makeFormat(from config: AudioSourceConfiguration) -> AudioFormat {
        AudioFormat(
            sampleRate: config.sampleRate,
            channelCount: config.channelCount,
            channelLayout: config.channelLayout,
            bitDepth: config.bitDepth
        )
    }

    private static func generateBuffer(
        waveform: ToneWaveform, frequency: Double, amplitude: Float,
        sampleRate: Double, samplesPerBuffer: Int,
        channelCount: Int, bytesPerSample: Int,
        globalSampleIndex: Int64
    ) -> Data {
        var data = Data(count: samplesPerBuffer * channelCount * bytesPerSample)
        data.withUnsafeMutableBytes { rawBuffer in
            let floatBuffer = rawBuffer.bindMemory(to: Float.self)
            for sampleIndex in 0..<samplesPerBuffer {
                let phase = fmod(
                    Double(globalSampleIndex + Int64(sampleIndex)) * frequency / sampleRate,
                    1.0
                )
                let sample = generateSample(waveform: waveform, phase: phase, amplitude: amplitude)
                for channel in 0..<channelCount {
                    floatBuffer[sampleIndex * channelCount + channel] = sample
                }
            }
        }
        return data
    }

    /// Generates a single audio sample for the given waveform, phase, and amplitude.
    ///
    /// - Parameters:
    ///   - waveform: The waveform shape.
    ///   - phase: The current phase in the range 0.0 to 1.0.
    ///   - amplitude: The amplitude scaling factor.
    /// - Returns: A floating-point sample value.
    private static func generateSample(
        waveform: ToneWaveform,
        phase: Double,
        amplitude: Float
    ) -> Float {
        let raw: Float
        switch waveform {
        case .sine:
            raw = Float(sin(phase * 2.0 * .pi))
        case .square:
            raw = phase < 0.5 ? 1.0 : -1.0
        case .sawtooth:
            raw = Float(2.0 * phase - 1.0)
        case .triangle:
            raw = phase < 0.5 ? Float(4.0 * phase - 1.0) : Float(3.0 - 4.0 * phase)
        case .whiteNoise:
            raw = Float.random(in: -1.0...1.0)
        case .pinkNoise:
            raw = Float.random(in: -1.0...1.0) * 0.7
        case .brownNoise:
            raw = Float.random(in: -0.1...0.1)
        case .ebur128Calibration:
            raw = Float(sin(phase * 2.0 * .pi)) * 0.1
        }
        return raw * amplitude
    }
}
