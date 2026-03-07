// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Descriptor for a video input device.
public struct VideoDeviceInfo: Sendable, Identifiable, Hashable {
    /// Unique device identifier.
    public let id: String

    /// Human-readable device name.
    public let name: String

    /// Device manufacturer (if available).
    public let manufacturer: String?

    /// Device model identifier (if available).
    public let modelID: String?

    /// Camera position (front, back, unspecified).
    public let position: CameraPosition

    /// Camera device type.
    public let deviceType: CameraDeviceType

    /// How the device is connected.
    public let connectionType: DeviceConnectionType

    /// Whether the device has a flash.
    public let hasFlash: Bool

    /// Whether the device has a torch/flashlight.
    public let hasTorch: Bool

    /// Whether the device supports cinematic mode.
    public let supportsCinematic: Bool

    /// Whether the device supports depth data.
    public let supportsDepthData: Bool

    /// Creates a new video device info descriptor.
    ///
    /// - Parameters:
    ///   - id: Unique device identifier.
    ///   - name: Human-readable device name.
    ///   - manufacturer: Device manufacturer. Defaults to `nil`.
    ///   - modelID: Device model identifier. Defaults to `nil`.
    ///   - position: Camera position. Defaults to `.unspecified`.
    ///   - deviceType: Camera device type. Defaults to `.wideAngle`.
    ///   - connectionType: How the device is connected.
    ///   - hasFlash: Whether the device has a flash. Defaults to `false`.
    ///   - hasTorch: Whether the device has a torch. Defaults to `false`.
    ///   - supportsCinematic: Whether cinematic mode is supported. Defaults to `false`.
    ///   - supportsDepthData: Whether depth data is supported. Defaults to `false`.
    public init(
        id: String,
        name: String,
        manufacturer: String? = nil,
        modelID: String? = nil,
        position: CameraPosition = .unspecified,
        deviceType: CameraDeviceType = .wideAngle,
        connectionType: DeviceConnectionType,
        hasFlash: Bool = false,
        hasTorch: Bool = false,
        supportsCinematic: Bool = false,
        supportsDepthData: Bool = false
    ) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
        self.modelID = modelID
        self.position = position
        self.deviceType = deviceType
        self.connectionType = connectionType
        self.hasFlash = hasFlash
        self.hasTorch = hasTorch
        self.supportsCinematic = supportsCinematic
        self.supportsDepthData = supportsDepthData
    }
}
