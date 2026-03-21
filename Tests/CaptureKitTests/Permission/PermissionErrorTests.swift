// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("PermissionError", .timeLimit(.minutes(1)))
struct PermissionErrorTests {

    @Test("denied description includes type")
    func deniedDescription() {
        let error = PermissionError.denied(.microphone)
        #expect(error.description.contains("microphone"))
        #expect(error.description.contains("denied"))
    }

    @Test("restricted description includes type")
    func restrictedDescription() {
        let error = PermissionError.restricted(.camera)
        #expect(error.description.contains("camera"))
        #expect(error.description.contains("restricted"))
    }

    @Test("notAvailableOnPlatform description includes platform")
    func notAvailableDescription() {
        let error = PermissionError.notAvailableOnPlatform(
            .screenRecording, platform: "iOS")
        #expect(error.description.contains("iOS"))
        #expect(error.description.contains("screenRecording"))
    }

    @Test("requestFailed description includes reason")
    func requestFailedDescription() {
        let error = PermissionError.requestFailed(
            .bluetooth, reason: "timeout")
        #expect(error.description.contains("timeout"))
        #expect(error.description.contains("bluetooth"))
    }

    @Test("conforms to Error")
    func conformsToError() {
        let error: any Error = PermissionError.denied(.microphone)
        _ = error
    }

    @Test("conforms to Sendable")
    func conformsToSendable() {
        let error: any Sendable = PermissionError.denied(.microphone)
        _ = error
    }
}
