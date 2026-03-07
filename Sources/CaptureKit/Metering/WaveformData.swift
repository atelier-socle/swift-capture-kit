// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Audio waveform data for visual rendering.
///
/// Provides amplitude data that consuming apps can use to draw waveforms —
/// from simple message-style bars to detailed DAW-style min/max displays.
public struct WaveformData: Sendable, Equatable {
    /// Timestamp of the waveform segment.
    public let timestamp: TimeInterval

    /// Duration of audio represented by this waveform.
    public let duration: TimeInterval

    /// Simplified amplitude bars (0.0–1.0 normalized).
    public let bars: [Float]

    /// Detailed min/max pairs per bucket.
    public let minMax: [WaveformBucket]

    /// Total number of audio samples represented.
    public let sampleCount: Int

    /// Creates new waveform data.
    ///
    /// - Parameters:
    ///   - timestamp: The timestamp of the waveform segment.
    ///   - duration: The duration of audio represented.
    ///   - bars: Simplified amplitude bars.
    ///   - minMax: Detailed min/max pairs per bucket.
    ///   - sampleCount: Total number of audio samples represented.
    public init(
        timestamp: TimeInterval,
        duration: TimeInterval,
        bars: [Float],
        minMax: [WaveformBucket],
        sampleCount: Int
    ) {
        self.timestamp = timestamp
        self.duration = duration
        self.bars = bars
        self.minMax = minMax
        self.sampleCount = sampleCount
    }
}

/// A single waveform bucket containing min/max sample values.
public struct WaveformBucket: Sendable, Equatable {
    /// Minimum sample value in this bucket (-1.0 to 1.0).
    public let min: Float
    /// Maximum sample value in this bucket (-1.0 to 1.0).
    public let max: Float
    /// RMS level of samples in this bucket (0.0 to 1.0).
    public let rms: Float

    /// Creates a new waveform bucket.
    ///
    /// - Parameters:
    ///   - min: The minimum sample value.
    ///   - max: The maximum sample value.
    ///   - rms: The RMS level.
    public init(min: Float, max: Float, rms: Float) {
        self.min = min
        self.max = max
        self.rms = rms
    }

    /// Amplitude (distance between min and max, 0.0–2.0).
    public var amplitude: Float { max - min }

    /// Normalized amplitude (0.0–1.0).
    public var normalizedAmplitude: Float { amplitude / 2.0 }
}

/// Waveform generation mode.
public enum WaveformMode: Sendable, Equatable {
    /// Simple mode: produces N amplitude bars (normalized 0.0–1.0).
    case simple(barCount: Int)

    /// Detailed mode: produces min/max/RMS per bucket of N samples.
    case detailed(samplesPerBucket: Int)

    /// Both simple and detailed data generated simultaneously.
    case both(barCount: Int, samplesPerBucket: Int)

    /// Disabled — no waveform generation (saves CPU).
    case disabled

    /// Message-style preset (50 bars).
    public static let message = WaveformMode.simple(barCount: 50)

    /// Podcast editing preset (100 bars).
    public static let podcastEdit = WaveformMode.simple(barCount: 100)

    /// DAW-style preset (256 samples per bucket).
    public static let daw = WaveformMode.detailed(samplesPerBucket: 256)

    /// High-resolution DAW (64 samples per bucket).
    public static let dawHighRes = WaveformMode.detailed(
        samplesPerBucket: 64)
}
