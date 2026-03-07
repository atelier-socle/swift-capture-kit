// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("BroadcastControlMessage")
struct BroadcastControlMessageTests {

    @Test("CaseIterable count is 3")
    func caseIterableCount() {
        #expect(BroadcastControlMessage.allCases.count == 3)
    }

    @Test("rawValues are stop, pause, and resume")
    func rawValues() {
        #expect(BroadcastControlMessage.stop.rawValue == "stop")
        #expect(BroadcastControlMessage.pause.rawValue == "pause")
        #expect(BroadcastControlMessage.resume.rawValue == "resume")
    }

    @Test("all cases exist")
    func allCasesExist() {
        let allCases = BroadcastControlMessage.allCases
        #expect(allCases.contains(.stop))
        #expect(allCases.contains(.pause))
        #expect(allCases.contains(.resume))
    }
}
