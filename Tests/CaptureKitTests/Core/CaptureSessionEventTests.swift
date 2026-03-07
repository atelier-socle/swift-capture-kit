// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CaptureSessionEvent")
struct CaptureSessionEventTests {

    @Test("Can create stateChanged event")
    func stateChangedEvent() {
        let event = CaptureSessionEvent.stateChanged(.capturing)
        if case .stateChanged(let state) = event {
            #expect(state == .capturing)
        } else {
            Issue.record("Expected stateChanged event")
        }
    }

    @Test("Can create permissionDenied event")
    func permissionDeniedEvent() {
        let event = CaptureSessionEvent.permissionDenied(.microphone)
        if case .permissionDenied(let permType) = event {
            #expect(permType == .microphone)
        } else {
            Issue.record("Expected permissionDenied event")
        }
    }

    @Test("Can create bitrateChanged event")
    func bitrateChangedEvent() {
        let event = CaptureSessionEvent.bitrateChanged(audio: 128_000, video: 5_000_000)
        if case .bitrateChanged(let audio, let video) = event {
            #expect(audio == 128_000)
            #expect(video == 5_000_000)
        } else {
            Issue.record("Expected bitrateChanged event")
        }
    }

    @Test("Can create droppedFrames event")
    func droppedFramesEvent() {
        let event = CaptureSessionEvent.droppedFrames(count: 5, reason: "CPU overload")
        if case .droppedFrames(let count, let reason) = event {
            #expect(count == 5)
            #expect(reason == "CPU overload")
        } else {
            Issue.record("Expected droppedFrames event")
        }
    }

    @Test("PermissionType CaseIterable count is six")
    func permissionTypeCaseCount() {
        #expect(PermissionType.allCases.count == 6)
    }

    @Test("CaptureQualityLevel Comparable ordering")
    func qualityLevelComparableOrdering() {
        #expect(CaptureQualityLevel.maximum > .high)
        #expect(CaptureQualityLevel.high > .medium)
        #expect(CaptureQualityLevel.medium > .low)
        #expect(CaptureQualityLevel.low > .minimum)
    }

    @Test("CaptureQualityLevel CaseIterable count is five")
    func qualityLevelCaseCount() {
        #expect(CaptureQualityLevel.allCases.count == 5)
    }
}
