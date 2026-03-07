// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Describes how an audio device is physically or wirelessly connected to the system.
public enum DeviceConnectionType: String, Sendable, CaseIterable {
    /// A device built into the hardware (e.g., internal microphone).
    case builtIn

    /// A device connected via USB.
    case usb

    /// A device connected via Thunderbolt.
    case thunderbolt

    /// A device connected via Bluetooth.
    case bluetooth

    /// A device connected via Continuity Camera (iPhone as webcam/mic).
    case continuityCamera

    /// A device connected via a wireless protocol other than Bluetooth.
    case wireless
}
