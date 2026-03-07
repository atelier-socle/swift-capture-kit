// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("SystemAudioCaptureMode")
struct SystemAudioCaptureModeTests {

    @Test("allApps equality")
    func allAppsEquality() {
        let modeA = SystemAudioCaptureMode.allApps
        let modeB = SystemAudioCaptureMode.allApps
        #expect(modeA == modeB)
    }

    @Test("specificApps with bundle IDs")
    func specificAppsWithBundleIDs() {
        let ids = ["com.apple.Music", "com.spotify.client"]
        let mode = SystemAudioCaptureMode.specificApps(ids)
        #expect(mode == .specificApps(["com.apple.Music", "com.spotify.client"]))
    }

    @Test("excludeApps with bundle IDs")
    func excludeAppsWithBundleIDs() {
        let ids = ["com.apple.Safari"]
        let mode = SystemAudioCaptureMode.excludeApps(ids)
        #expect(mode == .excludeApps(["com.apple.Safari"]))
    }

    @Test("Equatable: different modes are not equal")
    func differentModesAreNotEqual() {
        let allApps = SystemAudioCaptureMode.allApps
        let specific = SystemAudioCaptureMode.specificApps(["com.example.app"])
        let exclude = SystemAudioCaptureMode.excludeApps(["com.example.app"])

        #expect(allApps != specific)
        #expect(allApps != exclude)
        #expect(specific != exclude)
    }
}
