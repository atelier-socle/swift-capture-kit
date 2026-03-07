// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Configuration for a single camera input in a multi-camera session.
public struct MultiCameraInput: Sendable, Identifiable, Equatable {
    /// Unique identifier for this camera input.
    public let id: String

    /// Human-readable label (e.g., "host", "guest-1").
    public let label: String

    /// The video device to use.
    public let device: VideoDeviceInfo

    /// Video configuration for this camera.
    public var configuration: VideoSourceConfiguration

    /// Creates a new multi-camera input.
    ///
    /// - Parameters:
    ///   - device: The video device to use.
    ///   - label: A human-readable label for this input.
    ///   - configuration: The video source configuration. Defaults to `.default`.
    public init(
        device: VideoDeviceInfo,
        label: String,
        configuration: VideoSourceConfiguration = .default
    ) {
        self.id = "\(device.id)-\(label)"
        self.label = label
        self.device = device
        self.configuration = configuration
    }
}

/// Configuration for multi-camera capture sessions.
public struct MultiCameraConfiguration: Sendable {
    /// Camera inputs (minimum 2).
    public var cameras: [MultiCameraInput]

    /// Whether multi-camera hardware is required (vs fallback to single cam).
    public var requireMultiCam: Bool

    /// Creates a new multi-camera configuration.
    ///
    /// - Parameters:
    ///   - cameras: The camera inputs.
    ///   - requireMultiCam: Whether multi-camera hardware is required. Defaults to `true`.
    public init(cameras: [MultiCameraInput], requireMultiCam: Bool = true) {
        self.cameras = cameras
        self.requireMultiCam = requireMultiCam
    }

    /// Validates that the configuration has at least 2 cameras.
    ///
    /// - Throws: ``CaptureError/invalidConfiguration(_:)`` if fewer than 2 cameras.
    public func validate() throws {
        guard cameras.count >= 2 else {
            throw CaptureError.invalidConfiguration(
                "Multi-camera requires at least 2 cameras, got \(cameras.count)"
            )
        }
    }
}
