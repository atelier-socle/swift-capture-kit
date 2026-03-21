// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PermissionManager", .timeLimit(.minutes(1)))
struct PermissionManagerTests {

    @Test("initial status is a valid PermissionStatus")
    func initialStatus() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .microphone)
        #expect(PermissionStatus.allCases.contains(status))
    }

    @Test("status caches result")
    func statusCaches() async {
        let manager = PermissionManager()
        let first = await manager.status(for: .camera)
        let second = await manager.status(for: .camera)
        #expect(first == second)
    }

    @Test("clearCache forces re-query and returns consistent result")
    func clearCacheRequery() async {
        let manager = PermissionManager()
        let before = await manager.status(for: .microphone)
        await manager.clearCache(for: .microphone)
        let after = await manager.status(for: .microphone)
        #expect(before == after)
    }

    @Test("clearAllCaches clears everything and re-queries consistently")
    func clearAllCaches() async {
        let manager = PermissionManager()
        let micBefore = await manager.status(for: .microphone)
        let camBefore = await manager.status(for: .camera)
        await manager.clearAllCaches()
        let mic = await manager.status(for: .microphone)
        let cam = await manager.status(for: .camera)
        #expect(mic == micBefore)
        #expect(cam == camBefore)
    }

    @Test(
        "request returns a valid status",
        .enabled(if: !TestEnvironment.isCI, "Triggers system permission prompt"))
    func requestInitial() async {
        let manager = PermissionManager()
        let result = await manager.request(.microphone)
        #expect(PermissionStatus.allCases.contains(result))
    }

    @Test(
        "requestAll for multiple types returns all requested",
        .enabled(if: !TestEnvironment.isCI, "Triggers system permission prompt"))
    func requestAllMultiple() async {
        let manager = PermissionManager()
        let results = await manager.requestAll(
            for: [.microphone, .camera])
        #expect(results.count == 2)
        #expect(results[.microphone] != nil)
        #expect(results[.camera] != nil)
    }

    @Test("permissionChanges stream exists")
    func permissionChangesStream() async {
        let manager = PermissionManager()
        _ = await manager.permissionChanges
    }

    @Test("all PermissionType cases queryable")
    func allTypesQueryable() async {
        let manager = PermissionManager()
        for type in PermissionType.allCases {
            let status = await manager.status(for: type)
            #expect(PermissionStatus.allCases.contains(status))
        }
    }

    @Test("status for microphone returns valid status")
    func statusForMicrophone() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .microphone)
        #expect(PermissionStatus.allCases.contains(status))
    }

    @Test("status for camera returns valid status")
    func statusForCamera() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .camera)
        #expect(PermissionStatus.allCases.contains(status))
    }

    @Test("status for screenRecording returns valid status")
    func statusForScreenRecording() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .screenRecording)
        #expect(PermissionStatus.allCases.contains(status))
    }

    @Test("status for bluetooth is notDetermined")
    func statusForBluetooth() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .bluetooth)
        #expect(status == .notDetermined)
    }

    @Test("status for photoLibrary is notDetermined")
    func statusForPhotoLibrary() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .photoLibrary)
        #expect(status == .notDetermined)
    }

    @Test("status for mediaLibrary is notDetermined")
    func statusForMediaLibrary() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .mediaLibrary)
        #expect(status == .notDetermined)
    }

    @Test(
        "request for already authorized permission returns authorized immediately",
        .enabled(if: !TestEnvironment.isCI, "Triggers system permission prompt"))
    func requestAlreadyAuthorized() async {
        let manager = PermissionManager()
        let first = await manager.request(.microphone)
        if first == .authorized {
            let second = await manager.request(.microphone)
            #expect(second == .authorized)
        }
    }
}
