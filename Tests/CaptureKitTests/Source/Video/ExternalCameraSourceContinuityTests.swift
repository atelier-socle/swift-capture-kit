// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ExternalCameraSource continuity wiring", .timeLimit(.minutes(1)))
struct ExternalCameraSourceContinuityTests {

    private func makeDevice() -> VideoDeviceInfo {
        VideoDeviceInfo(id: "ext-1", name: "USB Camera", connectionType: .usb)
    }

    @Test("continuityCameraFeatures default is nil")
    func continuityCameraFeaturesDefaultIsNil() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ExternalCameraSource(
            device: makeDevice(), captureEngine: MockVideoCaptureEngine())
        let features = await source.continuityCameraFeatures
        #expect(features == nil)
    }

    @Test("startCapture with continuity features calls engine")
    func startCaptureWithContinuityFeaturesCalls() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let features = ContinuityCameraFeatures(
            centerStage: true, portraitMode: false, studioLight: false)
        let source = ExternalCameraSource(
            device: makeDevice(), captureEngine: engine)
        await source.setContinuityFeatures(features)
        _ = try await source.startCapture()
        let applied = await engine.lastContinuityFeatures
        #expect(applied != nil)
        #expect(applied?.centerStage == true)
        await source.stopCapture()
    }

    @Test("startCapture without continuity features does not call engine")
    func startCaptureWithoutContinuityFeatures() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = ExternalCameraSource(
            device: makeDevice(), captureEngine: engine)
        _ = try await source.startCapture()
        let applied = await engine.lastContinuityFeatures
        #expect(applied == nil)
        await source.stopCapture()
    }
}

@available(macOS 14.0, iOS 17.0, *)
extension ExternalCameraSource {
    func setContinuityFeatures(_ features: ContinuityCameraFeatures?) {
        self.continuityCameraFeatures = features
    }
}
