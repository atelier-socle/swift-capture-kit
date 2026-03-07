// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

private func makeDevice() -> VideoDeviceInfo {
    VideoDeviceInfo(id: "ext-1", name: "USB Camera", connectionType: .usb)
}

@Suite("ExternalCameraSource")
struct ExternalCameraSourceTests {

    @Test("has externalCamera source type")
    func sourceType() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = ExternalCameraSource(device: makeDevice())
        let type = await source.sourceType
        #expect(type == .externalCamera)
    }

    @Test("display name matches device name")
    func displayNameMatchesDeviceName() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let device = makeDevice()
        let source = ExternalCameraSource(device: device)
        let name = await source.displayName
        #expect(name == "USB Camera")
    }

    @Test("stores selected device")
    func storesSelectedDevice() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let device = makeDevice()
        let source = ExternalCameraSource(device: device)
        let selected = await source.selectedDevice
        #expect(selected == device)
    }

    @Test("is not capturing initially")
    func notCapturingInitially() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = ExternalCameraSource(device: makeDevice())
        let capturing = await source.isCapturing
        #expect(capturing == false)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = ExternalCameraSource(device: makeDevice())
        try await source.configure(.default)
        let format = await source.activeFormat
        #expect(format != nil)
    }

    @Test("startCapture sets isCapturing")
    func startCaptureSetsIsCapturing() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = ExternalCameraSource(device: makeDevice())
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = ExternalCameraSource(device: makeDevice())
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)

        await source.stopCapture()
        let stopped = await source.isCapturing
        #expect(stopped == false)
    }

    @Test("availability requires camera permission")
    func availabilityRequiresCameraPermission() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = ExternalCameraSource(device: makeDevice())
        let availability = source.availability
        #expect(availability.requiredPermissions.contains(.camera))
    }
}
