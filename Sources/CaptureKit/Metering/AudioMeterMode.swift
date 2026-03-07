// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Metering mode for the AudioMeter.
public enum AudioMeterMode: String, Sendable, CaseIterable {
    /// Peak level only (fastest, lowest CPU).
    case peak
    /// RMS level only.
    case rms
    /// Both peak and RMS (default).
    case peakAndRMS
    /// EBU R128 loudness metering (integrated, momentary, short-term).
    case loudness
    /// Full metering: peak, RMS, loudness, true peak.
    case full
}
