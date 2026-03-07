// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CinematicCameraSource")
struct CinematicCameraSourceTests {

    @Test("has cinematicCamera source type")
    func sourceType() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource()
        let type = await source.sourceType
        #expect(type == .cinematicCamera)
    }

    @Test("default fNumber is 2.8")
    func defaultFNumber() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource()
        let fNumber = await source.fNumber
        #expect(fNumber == 2.8)
    }

    @Test("default focus subject is automatic")
    func defaultFocusSubject() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource()
        let subject = await source.focusSubject
        #expect(subject == .automatic)
    }

    @Test("fNumber default is within valid range")
    func fNumberWithinValidRange() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource()
        let fNumber = await source.fNumber
        #expect(fNumber >= 1.4)
        #expect(fNumber <= 16.0)
    }

    @Test("rackFocus updates focus subject")
    func rackFocusUpdatesFocusSubject() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource()
        let initial = await source.focusSubject
        #expect(initial == .automatic)

        await source.rackFocus(to: .point(x: 0.5, y: 0.5), duration: 0.3)
        let updated = await source.focusSubject
        #expect(updated == .point(x: 0.5, y: 0.5))
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource()
        try await source.configure(.cinematic)
        let format = await source.activeFormat
        #expect(format != nil)
    }

    @Test("startCapture and stopCapture state transitions")
    func startAndStopCaptureStateTransitions() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource(captureEngine: MockVideoCaptureEngine())

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
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource()
        let availability = source.availability
        #expect(availability.requiredPermissions.contains(.camera))
    }
}
