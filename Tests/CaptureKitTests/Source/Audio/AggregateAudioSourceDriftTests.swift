// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AggregateAudioSource Drift Compensation", .timeLimit(.minutes(1)))
struct AggregateAudioSourceDriftTests {

    private func makeDevices() -> [AudioDeviceInfo] {
        [
            AudioDeviceInfo(
                id: "dev-1", name: "Device 1",
                connectionType: .usb, inputChannelCount: 2,
                supportedSampleRates: [.rate48000]),
            AudioDeviceInfo(
                id: "dev-2", name: "Device 2",
                connectionType: .usb, inputChannelCount: 2,
                supportedSampleRates: [.rate48000])
        ]
    }

    @Test("driftCompensation defaults to true")
    func driftCompensationDefaultsToTrue() async throws {
        guard #available(macOS 14.0, *) else { return }

        let source = AggregateAudioSource(
            devices: makeDevices(), captureEngine: MockAudioCaptureEngine())
        let drift = await source.driftCompensation
        #expect(drift == true)
    }

    @Test("clockSource defaults to nil")
    func clockSourceDefaultsToNil() async throws {
        guard #available(macOS 14.0, *) else { return }

        let source = AggregateAudioSource(
            devices: makeDevices(), captureEngine: MockAudioCaptureEngine())
        let clock = await source.clockSource
        #expect(clock == nil)
    }
}
