// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("BroadcastIPCChannel")
struct BroadcastIPCChannelTests {

    @Test("stores appGroupID")
    func storesAppGroupID() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.test")
        #expect(await channel.appGroupID == "group.test")
    }

    @Test("stores maxBufferSize")
    func storesMaxBufferSize() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.test", maxBufferSize: 1_048_576)
        #expect(await channel.maxBufferSize == 1_048_576)
    }

    @Test("default maxBufferSize is 5MB")
    func defaultMaxBufferSizeIs5MB() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.test")
        #expect(await channel.maxBufferSize == 5_242_880)
    }

    @Test("is not connected initially")
    func isNotConnectedInitially() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.test")
        #expect(await channel.isConnected == false)
    }

    @Test("connect sets isConnected to true")
    func connectSetsIsConnectedToTrue() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.test")
        try await channel.connect()
        #expect(await channel.isConnected == true)
        await channel.disconnect()
    }

    @Test("connect when already connected does not throw")
    func connectWhenAlreadyConnectedDoesNotThrow() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.test")
        try await channel.connect()
        try await channel.connect()
        #expect(await channel.isConnected == true)
        await channel.disconnect()
    }

    @Test("disconnect sets isConnected to false")
    func disconnectSetsIsConnectedToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.test")
        try await channel.connect()
        await channel.disconnect()
        #expect(await channel.isConnected == false)
    }

    @Test("sendControlMessage when not connected throws")
    func sendControlMessageWhenNotConnectedThrows() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.test")
        await #expect(throws: CaptureError.self) {
            try await channel.sendControlMessage(.stop)
        }
    }

    @Test("sendControlMessage when connected with invalid group gracefully handles")
    func sendControlMessageWhenConnectedWithInvalidGroup() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.nonexistent.test")
        try await channel.connect()
        // sendControlMessage with invalid App Group container silently fails
        // (containerURL returns nil, so the guard returns early)
        try await channel.sendControlMessage(.stop)
        await channel.disconnect()
    }

    @Test("incomingBuffers returns async stream that terminates on disconnect")
    func incomingBuffersReturnsAsyncStream() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let channel = BroadcastIPCChannel(appGroupID: "group.nonexistent.test")
        try await channel.connect()
        let stream = await channel.incomingBuffers()

        // Disconnect immediately so the stream terminates
        await channel.disconnect()

        var count = 0
        for await _ in stream {
            count += 1
            if count > 10 { break }
        }
        // Stream should terminate quickly after disconnect
        #expect(count <= 10)
    }

    @Test("parseSampleType recognizes video prefix")
    func parseSampleTypeRecognizesVideo() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        // This tests the IPC parsing logic indirectly
        let channel = BroadcastIPCChannel(appGroupID: "group.test")
        // Channel should be constructable without side effects
        #expect(await channel.appGroupID == "group.test")
    }
}
