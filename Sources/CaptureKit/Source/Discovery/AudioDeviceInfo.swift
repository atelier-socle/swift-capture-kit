// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Describes a discovered audio input device and its capabilities.
public struct AudioDeviceInfo: Sendable, Identifiable, Hashable {
    /// The unique identifier of the audio device.
    public let id: String

    /// The human-readable name of the audio device.
    public let name: String

    /// The manufacturer of the audio device, if known.
    public let manufacturer: String?

    /// The model identifier of the audio device, if known.
    public let modelID: String?

    /// The physical or wireless connection type of the device.
    public let connectionType: DeviceConnectionType

    /// The number of input channels available on the device.
    public let inputChannelCount: Int

    /// The sample rates supported by the device.
    public let supportedSampleRates: [SampleRate]

    /// Whether this device is the system default audio input device.
    public let isDefault: Bool

    /// Creates a new audio device info descriptor.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the device.
    ///   - name: The human-readable name.
    ///   - manufacturer: The manufacturer name. Defaults to `nil`.
    ///   - modelID: The model identifier. Defaults to `nil`.
    ///   - connectionType: The connection type.
    ///   - inputChannelCount: The number of input channels.
    ///   - supportedSampleRates: The sample rates supported by the device.
    ///   - isDefault: Whether this is the default device. Defaults to `false`.
    public init(
        id: String,
        name: String,
        manufacturer: String? = nil,
        modelID: String? = nil,
        connectionType: DeviceConnectionType,
        inputChannelCount: Int,
        supportedSampleRates: [SampleRate],
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
        self.modelID = modelID
        self.connectionType = connectionType
        self.inputChannelCount = inputChannelCount
        self.supportedSampleRates = supportedSampleRates
        self.isDefault = isDefault
    }
}
