// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("SourceCapabilities")
struct SourceCapabilitiesTests {

    @Test("available preset has correct values")
    func availablePreset() {
        let availability = SourceAvailability.available
        #expect(availability.isAvailableOnCurrentPlatform == true)
        #expect(availability.isAvailableOnCurrentDevice == true)
        #expect(availability.requiredPermissions.isEmpty)
        #expect(availability.minimumOSVersion == nil)
        #expect(availability.notes == nil)
    }

    @Test("unavailable factory method sets correct values")
    func unavailableFactory() {
        let availability = SourceAvailability.unavailable(reason: "Not supported")
        #expect(availability.isAvailableOnCurrentPlatform == false)
        #expect(availability.isAvailableOnCurrentDevice == false)
        #expect(availability.requiredPermissions.isEmpty)
        #expect(availability.notes == "Not supported")
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = SourceAvailability.available
        let b = SourceAvailability.available
        #expect(a == b)

        let c = SourceAvailability.unavailable(reason: "test")
        #expect(a != c)
    }

    @Test("Init with custom values")
    func initWithCustomValues() {
        let availability = SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: false,
            requiredPermissions: [.microphone, .camera],
            minimumOSVersion: "14.0",
            notes: "Requires external hardware"
        )
        #expect(availability.isAvailableOnCurrentPlatform == true)
        #expect(availability.isAvailableOnCurrentDevice == false)
        #expect(availability.requiredPermissions == [.microphone, .camera])
        #expect(availability.minimumOSVersion == "14.0")
        #expect(availability.notes == "Requires external hardware")
    }
}
