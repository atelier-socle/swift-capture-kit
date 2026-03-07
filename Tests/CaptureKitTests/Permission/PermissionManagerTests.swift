// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PermissionManager")
struct PermissionManagerTests {

    @Test("initial status is notDetermined")
    func initialStatus() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .microphone)
        #expect(status == .notDetermined)
    }

    @Test("status caches result")
    func statusCaches() async {
        let manager = PermissionManager()
        let first = await manager.status(for: .camera)
        let second = await manager.status(for: .camera)
        #expect(first == second)
    }

    @Test("clearCache forces re-query")
    func clearCacheRequery() async {
        let manager = PermissionManager()
        _ = await manager.status(for: .microphone)
        await manager.clearCache(for: .microphone)
        let status = await manager.status(for: .microphone)
        #expect(status == .notDetermined)
    }

    @Test("clearAllCaches clears everything")
    func clearAllCaches() async {
        let manager = PermissionManager()
        _ = await manager.status(for: .microphone)
        _ = await manager.status(for: .camera)
        await manager.clearAllCaches()
        let mic = await manager.status(for: .microphone)
        let cam = await manager.status(for: .camera)
        #expect(mic == .notDetermined)
        #expect(cam == .notDetermined)
    }

    @Test("request returns notDetermined for initial")
    func requestInitial() async {
        let manager = PermissionManager()
        let result = await manager.request(.microphone)
        #expect(result == .notDetermined)
    }

    @Test("requestAll for multiple types")
    func requestAllMultiple() async {
        let manager = PermissionManager()
        let results = await manager.requestAll(
            for: [.microphone, .camera])
        #expect(results.count == 2)
        #expect(results[.microphone] == .notDetermined)
        #expect(results[.camera] == .notDetermined)
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
            #expect(status == .notDetermined)
        }
    }

    @Test("status for microphone")
    func statusForMicrophone() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .microphone)
        #expect(status == .notDetermined)
    }

    @Test("status for camera")
    func statusForCamera() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .camera)
        #expect(status == .notDetermined)
    }

    @Test("status for screenRecording")
    func statusForScreenRecording() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .screenRecording)
        #expect(status == .notDetermined)
    }

    @Test("status for bluetooth")
    func statusForBluetooth() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .bluetooth)
        #expect(status == .notDetermined)
    }

    @Test("status for photoLibrary")
    func statusForPhotoLibrary() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .photoLibrary)
        #expect(status == .notDetermined)
    }

    @Test("status for mediaLibrary")
    func statusForMediaLibrary() async {
        let manager = PermissionManager()
        let status = await manager.status(for: .mediaLibrary)
        #expect(status == .notDetermined)
    }
}
