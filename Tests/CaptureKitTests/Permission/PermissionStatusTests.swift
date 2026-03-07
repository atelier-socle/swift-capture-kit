// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("PermissionStatus")
struct PermissionStatusTests {

    @Test("all 5 cases exist")
    func allCasesExist() {
        #expect(PermissionStatus.allCases.count == 5)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(PermissionStatus.notDetermined.rawValue == "notDetermined")
        #expect(PermissionStatus.authorized.rawValue == "authorized")
        #expect(PermissionStatus.denied.rawValue == "denied")
        #expect(PermissionStatus.restricted.rawValue == "restricted")
        #expect(PermissionStatus.provisional.rawValue == "provisional")
    }

    @Test("CaseIterable includes all statuses")
    func caseIterable() {
        let statuses = PermissionStatus.allCases
        #expect(statuses.contains(.notDetermined))
        #expect(statuses.contains(.authorized))
        #expect(statuses.contains(.denied))
        #expect(statuses.contains(.restricted))
        #expect(statuses.contains(.provisional))
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let status: any Sendable = PermissionStatus.authorized
        _ = status
    }

    @Test("Equatable conformance")
    func equatable() {
        #expect(PermissionStatus.authorized == .authorized)
        #expect(PermissionStatus.denied != .authorized)
    }
}
