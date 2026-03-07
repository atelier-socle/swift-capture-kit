// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ScreenCaptureSource")
struct ScreenCaptureSourceTests {

    @Test("has screenCapture source type")
    func hasScreenCaptureSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        #expect(await source.sourceType == .screenCapture)
    }

    @Test("generates unique source ID")
    func generatesUniqueSourceID() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source1 = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        let source2 = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 2)))
        let id1 = await source1.sourceID
        let id2 = await source2.sourceID
        #expect(id1 != id2)
    }

    @Test("display name reflects screenCaptureKit mode")
    func displayNameReflectsScreenCaptureKitMode() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        let name = await source.displayName
        #expect(name == "Screen Capture (macOS)")
    }

    @Test("display name reflects replayKit mode")
    func displayNameReflectsReplayKitMode() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .replayKit)
        let name = await source.displayName
        #expect(name == "Screen Recording (In-App)")
    }

    @Test("display name reflects broadcastExtension mode")
    func displayNameReflectsBroadcastExtensionMode() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .broadcastExtension(appGroupID: "group.test"))
        let name = await source.displayName
        #expect(name == "Screen Broadcast")
    }

    @Test("is not capturing initially")
    func isNotCapturingInitially() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        #expect(await source.isCapturing == false)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
            try await source.configure(.default)
            #expect(await source.activeFormat != nil)
        #endif
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
            try await source.configure(.default)
            try await source.startCapture()
            await #expect(throws: CaptureError.self) {
                try await source.configure(.default)
            }
            try await source.stopCapture()
        #endif
    }

    @Test("startCapture sets isCapturing to true")
    func startCaptureSetsIsCapturingToTrue() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
            try await source.configure(.default)
            try await source.startCapture()
            #expect(await source.isCapturing == true)
            try await source.stopCapture()
        #endif
    }

    @Test("startCapture while capturing throws")
    func startCaptureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
            try await source.configure(.default)
            try await source.startCapture()
            await #expect(throws: CaptureError.self) {
                try await source.startCapture()
            }
            try await source.stopCapture()
        #endif
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
            try await source.configure(.default)
            try await source.startCapture()
            try await source.stopCapture()
            #expect(await source.isCapturing == false)
        #endif
    }

    @Test("replayKit mode throws on macOS")
    func replayKitModeThrowsOnMacOS() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .replayKit)
            await #expect(throws: CaptureError.self) {
                try await source.configure(.default)
            }
        #endif
    }

    @Test("broadcastExtension mode throws on macOS")
    func broadcastExtensionModeThrowsOnMacOS() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .broadcastExtension(appGroupID: "group.test"))
            await #expect(throws: CaptureError.self) {
                try await source.configure(.default)
            }
        #endif
    }

    @Test("screenCaptureKit configuration is settable")
    func screenCaptureKitConfigurationIsSettable() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        let config = await source.screenCaptureKitConfiguration
        #expect(config == .default)
    }

    @Test("availability requires screen recording on macOS")
    func availabilityRequiresScreenRecordingOnMacOS() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
            let availability = await source.availability
            #expect(availability.requiredPermissions.contains(.screenRecording))
        #endif
    }
}
