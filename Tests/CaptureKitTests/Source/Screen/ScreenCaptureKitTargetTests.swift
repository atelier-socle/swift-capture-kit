// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ScreenCaptureKitTarget", .timeLimit(.minutes(1)))
struct ScreenCaptureKitTargetTests {

    @Test("display target equality")
    func displayTargetEquality() {
        let target = ScreenCaptureKitTarget.display(displayID: 1)
        let same = ScreenCaptureKitTarget.display(displayID: 1)
        #expect(target == same)
    }

    @Test("window target equality")
    func windowTargetEquality() {
        let target = ScreenCaptureKitTarget.window(windowID: 42)
        let same = ScreenCaptureKitTarget.window(windowID: 42)
        #expect(target == same)
    }

    @Test("application target stores bundleID")
    func applicationTargetStoresBundleID() {
        let target = ScreenCaptureKitTarget.application(bundleID: "com.apple.Safari")
        let same = ScreenCaptureKitTarget.application(bundleID: "com.apple.Safari")
        let different = ScreenCaptureKitTarget.application(bundleID: "com.apple.Mail")
        #expect(target == same)
        #expect(target != different)
    }

    @Test("region target stores coordinates")
    func regionTargetStoresCoordinates() {
        let target = ScreenCaptureKitTarget.region(x: 10, y: 20, width: 300, height: 400, displayID: 1)
        let same = ScreenCaptureKitTarget.region(x: 10, y: 20, width: 300, height: 400, displayID: 1)
        let different = ScreenCaptureKitTarget.region(x: 0, y: 0, width: 100, height: 100, displayID: 2)
        #expect(target == same)
        #expect(target != different)
    }

    @Test("different targets are not equal")
    func differentTargetsAreNotEqual() {
        let display = ScreenCaptureKitTarget.display(displayID: 1)
        let window = ScreenCaptureKitTarget.window(windowID: 1)
        #expect(display != window)
    }

    @Test("Sendable conformance")
    func sendableConformance() async {
        let target = ScreenCaptureKitTarget.display(displayID: 1)
        let result = await Task { target }.value
        #expect(result == target)
    }
}
