// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

private func makeDevice(id: String, name: String) -> VideoDeviceInfo {
    VideoDeviceInfo(id: id, name: name, connectionType: .usb)
}

private func makeValidConfig() -> MultiCameraConfiguration {
    let dev1 = makeDevice(id: "cam-1", name: "Camera 1")
    let dev2 = makeDevice(id: "cam-2", name: "Camera 2")
    return MultiCameraConfiguration(cameras: [
        MultiCameraInput(device: dev1, label: "host"),
        MultiCameraInput(device: dev2, label: "guest")
    ])
}

@Suite("MultiCameraSource")
struct MultiCameraSourceTests {

    @Test("has multiCamera source type")
    func sourceType() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = MultiCameraSource(configuration: makeValidConfig())
        let type = await source.sourceType
        #expect(type == .multiCamera)
    }

    @Test("stores camera configuration")
    func storesCameraConfiguration() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let config = makeValidConfig()
        let source = MultiCameraSource(configuration: config)
        let stored = await source.multiCameraConfiguration
        #expect(stored.cameras.count == 2)
        #expect(stored.requireMultiCam == true)
    }

    @Test("cameraLabels returns all labels")
    func cameraLabelsReturnsAllLabels() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = MultiCameraSource(configuration: makeValidConfig())
        let labels = await source.cameraLabels
        #expect(labels == ["host", "guest"])
    }

    @Test("activeCameraCount matches cameras count")
    func activeCameraCountMatchesCamerasCount() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = MultiCameraSource(configuration: makeValidConfig())
        let count = await source.activeCameraCount
        #expect(count == 2)
    }

    @Test("configure validates minimum 2 cameras")
    func configureValidatesMinimum2Cameras() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = MultiCameraSource(configuration: makeValidConfig())
        try await source.configure(.default)
        let format = await source.activeFormat
        #expect(format != nil)
    }

    @Test("configure with 1 camera throws")
    func configureWith1CameraThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let singleCamConfig = MultiCameraConfiguration(cameras: [
            MultiCameraInput(
                device: makeDevice(id: "cam-1", name: "Camera 1"),
                label: "solo"
            )
        ])
        let source = MultiCameraSource(configuration: singleCamConfig)

        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
    }

    @Test("stream for unknown label throws deviceNotFound")
    func streamForUnknownLabelThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = MultiCameraSource(configuration: makeValidConfig())

        await #expect(throws: CaptureError.self) {
            _ = try await source.stream(for: "unknown")
        }
    }

    @Test("stream for known label succeeds")
    func streamForKnownLabelSucceeds() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = MultiCameraSource(configuration: makeValidConfig(), captureEngine: MockVideoCaptureEngine())
        let stream = try await source.stream(for: "host")
        // Stream should be returned without throwing.
        _ = stream
    }

    @Test("startCapture and stopCapture state transitions")
    func startAndStopCaptureStateTransitions() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = MultiCameraSource(configuration: makeValidConfig(), captureEngine: MockVideoCaptureEngine())

        let initialCapturing = await source.isCapturing
        #expect(initialCapturing == false)

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

        let source = MultiCameraSource(configuration: makeValidConfig())
        let availability = source.availability
        #expect(availability.requiredPermissions.contains(.camera))
    }
}
