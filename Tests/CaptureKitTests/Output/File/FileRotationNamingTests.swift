// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("FileRotationNaming")
struct FileRotationNamingTests {

    @Test("all 3 naming patterns exist")
    func allPatternsExist() {
        #expect(FileRotationNaming.allCases.count == 3)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(FileRotationNaming.timestamp.rawValue == "timestamp")
        #expect(FileRotationNaming.sequential.rawValue == "sequential")
        #expect(FileRotationNaming.unixTimestamp.rawValue == "unixTimestamp")
    }

    @Test("CaseIterable includes all patterns")
    func caseIterable() {
        let patterns = FileRotationNaming.allCases
        #expect(patterns.contains(.timestamp))
        #expect(patterns.contains(.sequential))
        #expect(patterns.contains(.unixTimestamp))
    }
}
