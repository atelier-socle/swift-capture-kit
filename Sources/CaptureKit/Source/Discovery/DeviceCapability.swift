// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Runtime device capabilities for distinguishing iPad vs iPhone features.
///
/// SPM doesn't have a separate `.iPadOS` target — it uses `.iOS`.
/// These capabilities are queried at runtime to determine which
/// features are available on the current device.
public enum DeviceCapability: String, Sendable, CaseIterable {
    /// USB audio input (iPadOS via USB-C, macOS — NOT iPhone without adapter).
    case usbAudioInput
    /// External camera via USB-C (iPadOS with USB-C, macOS).
    case externalCamera
    /// Stage Manager multi-window (iPadOS 16+, macOS).
    case stageManager
    /// Thunderbolt peripherals (iPadOS with M-chip, macOS).
    case thunderbolt
    /// Apple Pencil input for annotation overlays (iPadOS only).
    case pencilInput
    /// Multi-camera simultaneous capture (iPhone 11+, iPadOS).
    case multiCamera
    /// Spatial audio capture (visionOS).
    case spatialAudio
    /// Screen capture via ScreenCaptureKit (macOS only).
    case screenCaptureKit
}

/// Queries the current device's capture capabilities at runtime.
public struct DeviceCapabilities: Sendable {

    /// Query all capabilities available on the current device.
    ///
    /// - Returns: A set of device capabilities available on this device.
    public static func available() -> Set<DeviceCapability> {
        var capabilities = Set<DeviceCapability>()

        #if os(macOS)
            capabilities.insert(.usbAudioInput)
            capabilities.insert(.externalCamera)
            capabilities.insert(.stageManager)
            capabilities.insert(.thunderbolt)
            capabilities.insert(.screenCaptureKit)
            capabilities.insert(.multiCamera)
        #elseif os(iOS)
            capabilities.insert(.multiCamera)
        #endif

        #if os(visionOS)
            capabilities.insert(.spatialAudio)
        #endif

        return capabilities
    }

    /// Check if a specific capability is available.
    ///
    /// - Parameter capability: The capability to check.
    /// - Returns: Whether the capability is available.
    public static func isAvailable(
        _ capability: DeviceCapability
    ) -> Bool {
        available().contains(capability)
    }
}
