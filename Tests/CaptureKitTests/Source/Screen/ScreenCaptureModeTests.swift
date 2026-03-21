// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ScreenCaptureMode", .timeLimit(.minutes(1)))
struct ScreenCaptureModeTests {

    @Test("screenCaptureKit mode with display target")
    func screenCaptureKitDisplayTarget() {
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        let same = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        #expect(mode == same)
    }

    @Test("screenCaptureKit mode with window target")
    func screenCaptureKitWindowTarget() {
        let mode = ScreenCaptureMode.screenCaptureKit(.window(windowID: 42))
        let same = ScreenCaptureMode.screenCaptureKit(.window(windowID: 42))
        #expect(mode == same)
    }

    @Test("screenCaptureKit mode with application target")
    func screenCaptureKitApplicationTarget() {
        let mode = ScreenCaptureMode.screenCaptureKit(.application(bundleID: "com.apple.Safari"))
        let same = ScreenCaptureMode.screenCaptureKit(.application(bundleID: "com.apple.Safari"))
        #expect(mode == same)
    }

    @Test("screenCaptureKit mode with region target")
    func screenCaptureKitRegionTarget() {
        let mode = ScreenCaptureMode.screenCaptureKit(.region(x: 0, y: 0, width: 100, height: 100, displayID: 1))
        let same = ScreenCaptureMode.screenCaptureKit(.region(x: 0, y: 0, width: 100, height: 100, displayID: 1))
        #expect(mode == same)
    }

    @Test("replayKit mode equality")
    func replayKitModeEquality() {
        let mode = ScreenCaptureMode.replayKit
        #expect(mode == .replayKit)
    }

    @Test("broadcastExtension mode stores appGroupID")
    func broadcastExtensionStoresAppGroupID() {
        let mode = ScreenCaptureMode.broadcastExtension(appGroupID: "group.com.test")
        let different = ScreenCaptureMode.broadcastExtension(appGroupID: "group.com.other")
        #expect(mode != different)
    }

    @Test("different modes are not equal")
    func differentModesAreNotEqual() {
        let replayKit = ScreenCaptureMode.replayKit
        let screenCaptureKit = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        #expect(replayKit != screenCaptureKit)
    }

    @Test("Sendable conformance")
    func sendableConformance() async {
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        let result = await Task { mode }.value
        #expect(result == mode)
    }
}
