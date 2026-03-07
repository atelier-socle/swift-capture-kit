// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Unified metering event combining audio and video metrics.
public enum MeteringEvent: Sendable {
    /// Audio level measurement.
    case audioLevel(AudioLevelSample)
    /// Video frame statistics.
    case videoMetrics(FrameStatisticsSample)
    /// Audio waveform data (for visual rendering).
    case waveform(WaveformData)
}
