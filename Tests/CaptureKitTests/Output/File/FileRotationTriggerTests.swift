// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileRotationTrigger")
struct FileRotationTriggerTests {

    @Test("duration trigger stores seconds")
    func durationStoresSeconds() {
        let trigger = FileRotationTrigger.duration(300)
        #expect(trigger == .duration(300))
    }

    @Test("size trigger stores bytes")
    func sizeStoresBytes() {
        let trigger = FileRotationTrigger.size(1_048_576)
        #expect(trigger == .size(1_048_576))
    }

    @Test("durationOrSize stores both values")
    func durationOrSizeStoresBoth() {
        let trigger = FileRotationTrigger.durationOrSize(
            duration: 60, size: 10_000_000)
        #expect(trigger == .durationOrSize(duration: 60, size: 10_000_000))
    }

    @Test("different triggers are not equal")
    func differentTriggersNotEqual() {
        #expect(FileRotationTrigger.duration(60) != .size(60))
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let trigger: any Sendable = FileRotationTrigger.duration(60)
        _ = trigger
    }
}
