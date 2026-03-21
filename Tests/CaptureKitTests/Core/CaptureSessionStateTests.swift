// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CaptureSessionState", .timeLimit(.minutes(1)))
struct CaptureSessionStateTests {

    @Test("All eight cases exist")
    func allCasesExist() {
        let allCases: [CaptureSessionState] = [
            .idle, .configuring, .ready, .starting,
            .capturing, .paused, .stopping, .error
        ]
        for state in allCases {
            #expect(CaptureSessionState.allCases.contains(state))
        }
    }

    @Test("CaseIterable count is eight")
    func caseIterableCount() {
        #expect(CaptureSessionState.allCases.count == 8)
    }

    @Test("isActive returns true for capturing and paused")
    func isActiveTrueForCapturingAndPaused() {
        #expect(CaptureSessionState.capturing.isActive)
        #expect(CaptureSessionState.paused.isActive)
    }

    @Test("isActive returns false for non-active states")
    func isActiveFalseForNonActiveStates() {
        let inactive: [CaptureSessionState] = [
            .idle, .configuring, .ready, .starting, .stopping, .error
        ]
        for state in inactive {
            #expect(!state.isActive)
        }
    }

    @Test("isTerminal returns true for idle and error")
    func isTerminalTrueForIdleAndError() {
        #expect(CaptureSessionState.idle.isTerminal)
        #expect(CaptureSessionState.error.isTerminal)
    }

    @Test("isTerminal returns false for non-terminal states")
    func isTerminalFalseForNonTerminalStates() {
        let nonTerminal: [CaptureSessionState] = [
            .configuring, .ready, .starting, .capturing, .paused, .stopping
        ]
        for state in nonTerminal {
            #expect(!state.isTerminal)
        }
    }

    @Test("rawValue matches expected strings")
    func rawValues() {
        #expect(CaptureSessionState.idle.rawValue == "idle")
        #expect(CaptureSessionState.configuring.rawValue == "configuring")
        #expect(CaptureSessionState.ready.rawValue == "ready")
        #expect(CaptureSessionState.starting.rawValue == "starting")
        #expect(CaptureSessionState.capturing.rawValue == "capturing")
        #expect(CaptureSessionState.paused.rawValue == "paused")
        #expect(CaptureSessionState.stopping.rawValue == "stopping")
        #expect(CaptureSessionState.error.rawValue == "error")
    }

    @Test("Sendable conformance")
    func sendableConformance() {
        let state: any Sendable = CaptureSessionState.idle
        #expect(state is CaptureSessionState)
    }
}
