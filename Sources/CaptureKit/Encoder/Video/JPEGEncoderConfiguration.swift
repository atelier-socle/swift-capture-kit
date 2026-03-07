// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration for the Motion JPEG encoder via VideoToolbox.
/// Each frame encoded independently — no temporal compression.
/// Low latency but large file sizes. Legacy/specialized use.
public struct JPEGEncoderConfiguration: Sendable, Equatable {
    /// JPEG quality (0.0-1.0, where 1.0 is maximum quality).
    public var quality: Float
    /// Real-time encoding mode.
    public var realTime: Bool

    /// Creates a new JPEG encoder configuration.
    public init(quality: Float = 0.85, realTime: Bool = true) {
        self.quality = quality
        self.realTime = realTime
    }

    /// Validate quality is 0.0-1.0.
    public func validate() throws {
        guard quality >= 0.0 && quality <= 1.0 else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "jpeg",
                reason: "Quality \(quality) is outside the valid range 0.0...1.0"
            )
        }
    }

    /// High quality — 0.95, suitable for editing.
    public static let highQuality = JPEGEncoderConfiguration(
        quality: 0.95, realTime: true
    )

    /// Standard — 0.85, balanced.
    public static let standard = JPEGEncoderConfiguration(
        quality: 0.85, realTime: true
    )

    /// Low bandwidth — 0.5, for preview/monitoring.
    public static let lowBandwidth = JPEGEncoderConfiguration(
        quality: 0.5, realTime: true
    )
}
