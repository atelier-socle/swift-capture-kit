// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("PermissionChange")
struct PermissionChangeTests {

    @Test("stores type and statuses")
    func storesValues() {
        let change = PermissionChange(
            type: .microphone,
            oldStatus: .notDetermined,
            newStatus: .authorized
        )
        #expect(change.type == .microphone)
        #expect(change.oldStatus == .notDetermined)
        #expect(change.newStatus == .authorized)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = PermissionChange(
            type: .camera, oldStatus: .notDetermined,
            newStatus: .denied)
        let b = PermissionChange(
            type: .camera, oldStatus: .notDetermined,
            newStatus: .denied)
        #expect(a == b)
    }

    @Test("different values are not equal")
    func notEqual() {
        let a = PermissionChange(
            type: .camera, oldStatus: .notDetermined,
            newStatus: .authorized)
        let b = PermissionChange(
            type: .camera, oldStatus: .notDetermined,
            newStatus: .denied)
        #expect(a != b)
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let change: any Sendable = PermissionChange(
            type: .microphone, oldStatus: .notDetermined,
            newStatus: .authorized)
        _ = change
    }
}
