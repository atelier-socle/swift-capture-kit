// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CameraSource", .timeLimit(.minutes(1)))
struct CameraSourceTests {

    @Test("has builtInCamera source type")
    func sourceType() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource()
        let type = await source.sourceType
        #expect(type == .builtInCamera)
    }

    @Test("default position is back")
    func defaultPosition() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource()
        let position = await source.position
        #expect(position == .back)
    }

    @Test("default zoom factor is 1.0")
    func defaultZoomFactor() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource()
        let zoom = await source.zoomFactor
        #expect(zoom == 1.0)
    }

    @Test("default torch mode is off")
    func defaultTorchMode() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource()
        let torch = await source.torchMode
        #expect(torch == .off)
    }

    @Test("is not capturing initially")
    func notCapturingInitially() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource()
        let capturing = await source.isCapturing
        #expect(capturing == false)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource()
        try await source.configure(.default)
        let format = await source.activeFormat
        #expect(format != nil)
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource(captureEngine: MockVideoCaptureEngine())
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)

        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
        await source.stopCapture()
    }

    @Test("startCapture sets isCapturing")
    func startCaptureSetsIsCapturing() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource(captureEngine: MockVideoCaptureEngine())
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)
        await source.stopCapture()
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource(captureEngine: MockVideoCaptureEngine())
        _ = try await source.startCapture()
        let capturing = await source.isCapturing
        #expect(capturing == true)

        await source.stopCapture()
        let stopped = await source.isCapturing
        #expect(stopped == false)
    }

    @Test("switchCamera changes position")
    func switchCameraChangesPosition() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource(captureEngine: MockVideoCaptureEngine())
        let initial = await source.position
        #expect(initial == .back)

        try await source.switchCamera(to: .front)
        let updated = await source.position
        #expect(updated == .front)
    }

    @Test("availability requires camera permission")
    func availabilityRequiresCameraPermission() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CameraSource()
        let availability = source.availability
        #expect(availability.requiredPermissions.contains(.camera))
    }

    @Test("capturePhoto delegates to engine and returns photo")
    func capturePhotoDelegatesToEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let engine = MockVideoCaptureEngine()
        let source = CameraSource(captureEngine: engine)
        let photo = try await source.capturePhoto()
        #expect(photo.width == 1920)
        #expect(photo.height == 1080)
    }
}
