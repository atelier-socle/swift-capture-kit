// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AggregateAudioSource wiring")
struct AggregateAudioSourceWiringTests {

    private func makeDevices(count: Int) -> [AudioDeviceInfo] {
        (0..<count).map { i in
            AudioDeviceInfo(
                id: "device-\(i)",
                name: "Device \(i)",
                connectionType: .usb,
                inputChannelCount: 1,
                supportedSampleRates: [.rate48000],
                isDefault: i == 0
            )
        }
    }

    @Test("configure requires at least 2 devices")
    func configureRequiresAtLeast2Devices() async throws {
        guard #available(macOS 14.0, *) else { return }
        let source = AggregateAudioSource(devices: makeDevices(count: 1))
        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
    }

    @Test("configure with 2 devices succeeds")
    func configureWith2DevicesSucceeds() async throws {
        guard #available(macOS 14.0, *) else { return }
        let source = AggregateAudioSource(devices: makeDevices(count: 2))
        try await source.configure(.default)
        let format = await source.activeFormat
        #expect(format != nil)
    }

    @Test("driftCompensation default is true")
    func driftCompensationDefaultIsTrue() async throws {
        guard #available(macOS 14.0, *) else { return }
        let source = AggregateAudioSource(devices: makeDevices(count: 2))
        let drift = await source.driftCompensation
        #expect(drift == true)
    }

    @Test("clockSource default is nil")
    func clockSourceDefaultIsNil() async throws {
        guard #available(macOS 14.0, *) else { return }
        let source = AggregateAudioSource(devices: makeDevices(count: 2))
        let clock = await source.clockSource
        #expect(clock == nil)
    }

    @Test("sourceType is aggregate")
    func sourceTypeIsAggregate() async throws {
        guard #available(macOS 14.0, *) else { return }
        let source = AggregateAudioSource(devices: makeDevices(count: 2))
        let type = await source.sourceType
        #expect(type == .aggregate)
    }

    @Test("sourceID starts with aggregate prefix")
    func sourceIDStartsWithAggregatePrefix() async throws {
        guard #available(macOS 14.0, *) else { return }
        let source = AggregateAudioSource(devices: makeDevices(count: 2))
        let id = await source.sourceID
        #expect(id.hasPrefix("aggregate-"))
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, *) else { return }
        let engine = MockAudioCaptureEngine()
        let source = AggregateAudioSource(
            devices: makeDevices(count: 2), captureEngine: engine)
        try await source.configure(.default)
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingFalse() async throws {
        guard #available(macOS 14.0, *) else { return }
        let engine = MockAudioCaptureEngine()
        let source = AggregateAudioSource(
            devices: makeDevices(count: 2), captureEngine: engine)
        try await source.configure(.default)
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)
        await source.stopCapture()
        let stopped = await source.isCapturing
        #expect(stopped == false)
    }
}
