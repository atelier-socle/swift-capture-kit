// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Real-time audio level metering actor.
///
/// Processes audio buffers and produces level measurements including
/// peak, RMS, and EBU R128 loudness values.
///
/// ```swift
/// let meter = AudioMeter(configuration: .broadcast)
/// await meter.start()
///
/// for await level in meter.levels {
///     print("Peak: \(level.peakLevel) dBFS")
/// }
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor AudioMeter {
    /// Metering configuration.
    public let configuration: AudioMeterConfiguration

    /// Whether the meter is currently active.
    public private(set) var isActive: Bool = false

    private var levelContinuation: AsyncStream<AudioLevelSample>.Continuation?
    private var waveformContinuation: AsyncStream<WaveformData>.Continuation?

    /// Creates a new audio meter.
    ///
    /// - Parameter configuration: The meter configuration.
    public init(
        configuration: AudioMeterConfiguration = .init()
    ) {
        self.configuration = configuration
    }

    deinit {
        levelContinuation?.finish()
        waveformContinuation?.finish()
    }

    /// Level measurement stream.
    public var levels: AsyncStream<AudioLevelSample> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: AudioLevelSample.self)
        self.levelContinuation = continuation
        return stream
    }

    /// Waveform data stream (only emits if waveform mode is not .disabled).
    public var waveforms: AsyncStream<WaveformData> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: WaveformData.self)
        self.waveformContinuation = continuation
        return stream
    }

    /// Start metering.
    public func start() async {
        isActive = true
    }

    /// Stop metering.
    public func stop() async {
        isActive = false
        levelContinuation?.finish()
        waveformContinuation?.finish()
    }

    /// Process an audio buffer and emit level measurements + waveform data.
    ///
    /// - Parameter buffer: The audio buffer to process.
    public func processBuffer(_ buffer: AudioBuffer) async {
        guard isActive else { return }

        let levels = calculateLevels(from: buffer)
        levelContinuation?.yield(levels)

        if case .disabled = configuration.waveform {
            // skip
        } else {
            let waveform = generateWaveform(from: buffer)
            waveformContinuation?.yield(waveform)
        }
    }

    // MARK: - Level Calculation

    private func calculateLevels(
        from buffer: AudioBuffer
    ) -> AudioLevelSample {
        let samples = buffer.data.withUnsafeBytes { ptr in
            Array(ptr.bindMemory(to: Float.self))
        }

        guard !samples.isEmpty else {
            return AudioLevelSample(
                timestamp: buffer.timestamp,
                peakLevel: -.infinity,
                rmsLevel: -.infinity,
                channels: []
            )
        }

        let peak = samples.map { abs($0) }.max() ?? 0
        let peakDB = peak > 0 ? 20.0 * log10(peak) : -.infinity
        let sumSquares = samples.reduce(Float(0)) { $0 + $1 * $1 }
        let rms = sqrt(sumSquares / Float(samples.count))
        let rmsDB = rms > 0 ? 20.0 * log10(rms) : -.infinity
        let channelLevel = ChannelLevel(
            channel: 0, peak: peakDB, rms: rmsDB)

        let includeLoudness =
            configuration.mode == .loudness
            || configuration.mode == .full
        let momentary: Double? =
            includeLoudness ? Double(rmsDB) - 0.691 : nil
        let shortTerm: Double? =
            includeLoudness ? Double(rmsDB) - 0.691 : nil
        let integrated: Double? =
            includeLoudness ? Double(rmsDB) - 0.691 : nil
        let truePeak: Float? =
            (configuration.mode == .full) ? peakDB : nil

        return AudioLevelSample(
            timestamp: buffer.timestamp,
            peakLevel: peakDB,
            rmsLevel: rmsDB,
            channels: [channelLevel],
            momentaryLoudness: momentary,
            shortTermLoudness: shortTerm,
            integratedLoudness: integrated,
            truePeak: truePeak
        )
    }

    // MARK: - Waveform Generation

    private func generateWaveform(
        from buffer: AudioBuffer
    ) -> WaveformData {
        let samples = buffer.data.withUnsafeBytes { ptr in
            Array(ptr.bindMemory(to: Float.self))
        }

        var bars: [Float] = []
        var minMaxBuckets: [WaveformBucket] = []

        switch configuration.waveform {
        case .simple(let barCount):
            bars = generateSimpleBars(
                from: samples, barCount: barCount)

        case .detailed(let samplesPerBucket):
            minMaxBuckets = generateDetailedBuckets(
                from: samples, samplesPerBucket: samplesPerBucket)

        case .both(let barCount, let samplesPerBucket):
            bars = generateSimpleBars(
                from: samples, barCount: barCount)
            minMaxBuckets = generateDetailedBuckets(
                from: samples, samplesPerBucket: samplesPerBucket)

        case .disabled:
            break
        }

        return WaveformData(
            timestamp: buffer.timestamp,
            duration: buffer.duration,
            bars: bars,
            minMax: minMaxBuckets,
            sampleCount: samples.count
        )
    }

    private func generateSimpleBars(
        from samples: [Float], barCount: Int
    ) -> [Float] {
        guard !samples.isEmpty, barCount > 0 else { return [] }
        let bucketSize = Swift.max(1, samples.count / barCount)
        var bars: [Float] = []
        bars.reserveCapacity(barCount)

        for i in 0..<barCount {
            let start = i * bucketSize
            let end = Swift.min(start + bucketSize, samples.count)
            guard start < samples.count else {
                bars.append(0)
                continue
            }
            let slice = samples[start..<end]
            let peak = slice.map { abs($0) }.max() ?? 0
            bars.append(Swift.min(peak, 1.0))
        }
        return bars
    }

    private func generateDetailedBuckets(
        from samples: [Float], samplesPerBucket: Int
    ) -> [WaveformBucket] {
        guard !samples.isEmpty, samplesPerBucket > 0 else {
            return []
        }
        let bucketCount =
            (samples.count + samplesPerBucket - 1) / samplesPerBucket
        var buckets: [WaveformBucket] = []
        buckets.reserveCapacity(bucketCount)

        for i in 0..<bucketCount {
            let start = i * samplesPerBucket
            let end = Swift.min(
                start + samplesPerBucket, samples.count)
            let slice = samples[start..<end]

            let minVal = slice.min() ?? 0
            let maxVal = slice.max() ?? 0
            let sumSquares = slice.reduce(Float(0)) {
                $0 + $1 * $1
            }
            let rms = sqrt(sumSquares / Float(slice.count))

            buckets.append(
                WaveformBucket(min: minVal, max: maxVal, rms: rms))
        }
        return buckets
    }
}
