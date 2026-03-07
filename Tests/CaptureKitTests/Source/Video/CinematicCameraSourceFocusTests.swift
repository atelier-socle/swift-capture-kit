// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CinematicCameraSource focus wiring")
struct CinematicCameraSourceFocusTests {

    @Test("startCapture with point focus calls engine focus point")
    func startCaptureWithPointFocusCalls() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CinematicCameraSource(captureEngine: engine)
        await source.setFocusSubject(.point(x: 0.3, y: 0.7))
        _ = try await source.startCapture()
        let point = await engine.lastFocusPoint
        #expect(point != nil)
        #expect(point?.x == 0.3)
        #expect(point?.y == 0.7)
    }

    @Test("startCapture with automatic focus sets continuous mode")
    func startCaptureWithAutomaticFocus() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CinematicCameraSource(captureEngine: engine)
        _ = try await source.startCapture()
        let mode = await engine.lastFocusMode
        #expect(mode == .continuousAutoFocus)
    }

    @Test("rackFocus to point updates engine focus point")
    func rackFocusToPointUpdatesEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CinematicCameraSource(captureEngine: engine)
        _ = try await source.startCapture()
        await source.rackFocus(to: .point(x: 0.5, y: 0.5), duration: 0.3)
        let subject = await source.focusSubject
        #expect(subject == .point(x: 0.5, y: 0.5))
    }

    @Test("rackFocus to automatic sets continuous auto focus on engine")
    func rackFocusToAutomaticSetsMode() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CinematicCameraSource(captureEngine: engine)
        _ = try await source.startCapture()
        await source.rackFocus(to: .automatic, duration: 0.5)
        let mode = await engine.lastFocusMode
        #expect(mode == .continuousAutoFocus)
    }

    @Test("fNumber clamped to valid range")
    func fNumberClampedToValidRange() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = CinematicCameraSource(captureEngine: MockVideoCaptureEngine())
        await source.setFNumber(0.5)
        let low = await source.fNumber
        #expect(low == 1.4)

        await source.setFNumber(32.0)
        let high = await source.fNumber
        #expect(high == 16.0)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension CinematicCameraSource {
    func setFocusSubject(_ subject: CinematicFocusSubject) {
        self.focusSubject = subject
    }

    func setFNumber(_ value: Float) {
        self.fNumber = value
    }
}
