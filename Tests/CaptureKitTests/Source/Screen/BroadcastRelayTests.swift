// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("BroadcastRelay")
struct BroadcastRelayTests {

    @Test("stores appGroupID")
    func storesAppGroupID() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let relay = BroadcastRelay(appGroupID: "group.test")
        #expect(await relay.appGroupID == "group.test")
    }

    @Test("stores maxBufferSize")
    func storesMaxBufferSize() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let relay = BroadcastRelay(appGroupID: "group.test", maxBufferSize: 1_048_576)
        #expect(await relay.maxBufferSize == 1_048_576)
    }

    @Test("default maxBufferSize is 5MB")
    func defaultMaxBufferSizeIs5MB() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let relay = BroadcastRelay(appGroupID: "group.test")
        #expect(await relay.maxBufferSize == 5_242_880)
    }

    @Test("is not active initially")
    func isNotActiveInitially() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let relay = BroadcastRelay(appGroupID: "group.test")
        #expect(await relay.isActive == false)
    }

    @Test("broadcastStarted sets isActive to true")
    func broadcastStartedSetsIsActiveToTrue() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let relay = BroadcastRelay(appGroupID: "group.test")
        await relay.broadcastStarted()
        #expect(await relay.isActive == true)
        await relay.broadcastFinished()
    }

    @Test("broadcastFinished sets isActive to false")
    func broadcastFinishedSetsIsActiveToFalse() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let relay = BroadcastRelay(appGroupID: "group.test")
        await relay.broadcastStarted()
        await relay.broadcastFinished()
        #expect(await relay.isActive == false)
    }

    @Test("processSample when not active is a no-op")
    func processSampleWhenNotActiveIsNoOp() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let relay = BroadcastRelay(appGroupID: "group.test")
        await relay.processSample(data: Data([0x00]), sampleType: .video, timestamp: 1.0)
    }

    @Test("processSample when active succeeds")
    func processSampleWhenActiveSucceeds() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let relay = BroadcastRelay(appGroupID: "group.test")
        await relay.broadcastStarted()
        await relay.processSample(data: Data([0x00]), sampleType: .video, timestamp: 1.0)
        await relay.broadcastFinished()
    }
}
