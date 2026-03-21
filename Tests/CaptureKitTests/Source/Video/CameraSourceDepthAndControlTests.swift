// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CameraSource depth and control wiring", .timeLimit(.minutes(1)))
struct CameraSourceDepthAndControlTests {

    @Test("depthDataDelivery default is false")
    func depthDataDeliveryDefaultIsFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = CameraSource(captureEngine: MockVideoCaptureEngine())
        let depth = await source.depthDataDelivery
        #expect(depth == false)
    }

    @Test("captureControlEnabled default is false")
    func captureControlEnabledDefaultIsFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = CameraSource(captureEngine: MockVideoCaptureEngine())
        let control = await source.captureControlEnabled
        #expect(control == false)
    }

    @Test("startCapture with depthDataDelivery calls engine")
    func startCaptureWithDepthDataDeliveryCalls() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CameraSource(captureEngine: engine)
        try await source.setDepthDataDelivery(true)
        _ = try await source.startCapture()
        let enabled = await engine.depthDataDeliveryEnabled
        #expect(enabled == true)
        await source.stopCapture()
    }

    @Test("startCapture without depthDataDelivery does not call engine")
    func startCaptureWithoutDepthDataDelivery() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CameraSource(captureEngine: engine)
        _ = try await source.startCapture()
        let enabled = await engine.depthDataDeliveryEnabled
        #expect(enabled == false)
        await source.stopCapture()
    }
}
