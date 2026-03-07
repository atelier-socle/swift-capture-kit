// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("StreamOutputConfiguration")
struct StreamOutputConfigurationTests {

    @Test("initializes with endpoint")
    func initializesWithEndpoint() {
        let config = StreamOutputConfiguration(
            endpoint: "rtmp://live.example.com/app")
        #expect(config.endpoint == "rtmp://live.example.com/app")
    }

    @Test("default values")
    func defaultValues() {
        let config = StreamOutputConfiguration(endpoint: "test")
        #expect(config.streamKey == nil)
        #expect(config.autoReconnect == true)
        #expect(config.maxReconnectAttempts == 5)
        #expect(config.reconnectDelay == 2.0)
        #expect(config.connectionTimeout == 10.0)
    }

    @Test("custom values are stored")
    func customValues() {
        let config = StreamOutputConfiguration(
            endpoint: "srt://host:9000",
            streamKey: "abc123",
            autoReconnect: false,
            maxReconnectAttempts: 10,
            reconnectDelay: 5.0,
            connectionTimeout: 30.0
        )
        #expect(config.streamKey == "abc123")
        #expect(config.autoReconnect == false)
        #expect(config.maxReconnectAttempts == 10)
        #expect(config.reconnectDelay == 5.0)
        #expect(config.connectionTimeout == 30.0)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = StreamOutputConfiguration(endpoint: "test")
        let b = StreamOutputConfiguration(endpoint: "test")
        #expect(a == b)
    }

    @Test("different endpoints are not equal")
    func differentEndpointsNotEqual() {
        let a = StreamOutputConfiguration(endpoint: "a")
        let b = StreamOutputConfiguration(endpoint: "b")
        #expect(a != b)
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let config: any Sendable = StreamOutputConfiguration(
            endpoint: "test")
        _ = config
    }
}
