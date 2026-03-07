// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("StreamingOutput")
struct StreamingOutputTests {

    @Test("StreamingConnectionState CaseIterable count is five")
    func connectionStateCaseCount() {
        #expect(StreamingConnectionState.allCases.count == 5)
    }

    @Test("StreamingConnectionState rawValues match expected strings")
    func connectionStateRawValues() {
        #expect(StreamingConnectionState.disconnected.rawValue == "disconnected")
        #expect(StreamingConnectionState.connecting.rawValue == "connecting")
        #expect(StreamingConnectionState.connected.rawValue == "connected")
        #expect(StreamingConnectionState.reconnecting.rawValue == "reconnecting")
        #expect(StreamingConnectionState.failed.rawValue == "failed")
    }

    @Test("StreamingTransportQuality init and Equatable")
    func transportQualityInitAndEquatable() {
        let a = StreamingTransportQuality(score: 0.85, grade: .good, recommendedBitrate: 5_000_000)
        let b = StreamingTransportQuality(score: 0.85, grade: .good, recommendedBitrate: 5_000_000)
        #expect(a == b)
        #expect(a.score == 0.85)
        #expect(a.grade == .good)
        #expect(a.recommendedBitrate == 5_000_000)
    }
}
