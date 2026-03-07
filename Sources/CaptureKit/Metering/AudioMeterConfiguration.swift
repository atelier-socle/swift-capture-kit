// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Configuration for the AudioMeter.
public struct AudioMeterConfiguration: Sendable, Equatable {
    /// Metering mode.
    public var mode: AudioMeterMode

    /// Waveform generation mode (disabled by default to save CPU).
    public var waveform: WaveformMode

    /// Update rate in Hz (how often levels are sampled). Default 60 Hz.
    public var updateRate: Double

    /// Hold time for peak indicators in seconds. Default 2.0.
    public var peakHoldTime: TimeInterval

    /// Whether to apply A-weighting to level measurements.
    public var aWeighting: Bool

    /// Creates an audio meter configuration.
    ///
    /// - Parameters:
    ///   - mode: The metering mode.
    ///   - waveform: The waveform generation mode.
    ///   - updateRate: The update rate in Hz.
    ///   - peakHoldTime: The peak hold time in seconds.
    ///   - aWeighting: Whether to apply A-weighting.
    public init(
        mode: AudioMeterMode = .peakAndRMS,
        waveform: WaveformMode = .disabled,
        updateRate: Double = 60.0,
        peakHoldTime: TimeInterval = 2.0,
        aWeighting: Bool = false
    ) {
        self.mode = mode
        self.waveform = waveform
        self.updateRate = updateRate
        self.peakHoldTime = peakHoldTime
        self.aWeighting = aWeighting
    }

    /// Broadcast standard — full metering, 60 Hz, 3s peak hold.
    public static let broadcast = AudioMeterConfiguration(
        mode: .full, waveform: .disabled, updateRate: 60.0,
        peakHoldTime: 3.0, aWeighting: false)

    /// Podcast — peak and RMS, 30 Hz, message-style waveform.
    public static let podcast = AudioMeterConfiguration(
        mode: .peakAndRMS, waveform: .podcastEdit, updateRate: 30.0,
        peakHoldTime: 2.0, aWeighting: false)

    /// Loudness compliance — EBU R128, 10 Hz update.
    public static let loudnessCompliance = AudioMeterConfiguration(
        mode: .loudness, waveform: .disabled, updateRate: 10.0,
        peakHoldTime: 3.0, aWeighting: false)

    /// Voice message — peak and RMS + simple waveform (50 bars).
    public static let voiceMessage = AudioMeterConfiguration(
        mode: .peakAndRMS, waveform: .message, updateRate: 30.0,
        peakHoldTime: 2.0, aWeighting: false)

    /// DAW editing — full metering + detailed waveform.
    public static let dawEditing = AudioMeterConfiguration(
        mode: .full, waveform: .daw, updateRate: 60.0,
        peakHoldTime: 3.0, aWeighting: false)
}
