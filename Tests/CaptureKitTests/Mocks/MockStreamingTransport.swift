// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

actor MockStreamingTransport: StreamingTransport {
    private(set) var connectCallCount = 0
    private(set) var disconnectCallCount = 0
    private(set) var sentConfigurations: [StreamConfiguration] = []
    private(set) var sentPackets: [MediaPacket] = []
    private(set) var isConnected = false

    var shouldThrowOnConnect = false
    var shouldThrowOnSend = false

    func connect() async throws {
        connectCallCount += 1
        if shouldThrowOnConnect {
            throw MockTransportError.connectionFailed
        }
        isConnected = true
    }

    func sendConfiguration(_ config: StreamConfiguration) async throws {
        sentConfigurations.append(config)
    }

    func send(_ packet: MediaPacket) async throws {
        if shouldThrowOnSend {
            throw MockTransportError.sendFailed
        }
        sentPackets.append(packet)
    }

    func disconnect() async throws {
        disconnectCallCount += 1
        isConnected = false
    }
}

enum MockTransportError: Error {
    case connectionFailed
    case sendFailed
}
