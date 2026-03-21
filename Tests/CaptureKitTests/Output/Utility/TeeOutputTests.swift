// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("TeeOutput", .timeLimit(.minutes(1)))
struct TeeOutputTests {

    @Test("has tee output type")
    func hasTeeOutputType() {
        let tee = TeeOutput(outputs: [])
        #expect(tee.outputType == .tee)
    }

    @Test("childCount matches initial outputs")
    func childCountMatchesInitial() async {
        let children: [any CaptureOutput] = [
            MockCaptureOutput(outputID: "a"),
            MockCaptureOutput(outputID: "b")
        ]
        let tee = TeeOutput(outputs: children)
        #expect(await tee.childCount == 2)
    }

    @Test("prepare prepares all children")
    func preparePreparesAllChildren() async throws {
        let child1 = MockCaptureOutput(outputID: "c1")
        let child2 = MockCaptureOutput(outputID: "c2")
        let tee = TeeOutput(outputs: [child1, child2])
        try await tee.prepare(audioFormat: nil, videoFormat: nil)
        #expect(await child1.prepareCallCount == 1)
        #expect(await child2.prepareCallCount == 1)
        #expect(await tee.state == .active)
    }

    @Test("receiveAudio delivers to all children")
    func receiveAudioToAllChildren() async throws {
        let child1 = MockCaptureOutput(outputID: "c1")
        let child2 = MockCaptureOutput(outputID: "c2")
        let tee = TeeOutput(outputs: [child1, child2])
        try await tee.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await tee.receiveAudio(buffer)
        #expect(await child1.receiveAudioCallCount == 1)
        #expect(await child2.receiveAudioCallCount == 1)
    }

    @Test("receiveVideo delivers to all children")
    func receiveVideoToAllChildren() async throws {
        let child1 = MockCaptureOutput(outputID: "c1")
        let child2 = MockCaptureOutput(outputID: "c2")
        let tee = TeeOutput(outputs: [child1, child2])
        try await tee.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await tee.receiveVideo(frame)
        #expect(await child1.receiveVideoCallCount == 1)
        #expect(await child2.receiveVideoCallCount == 1)
    }

    @Test("finalize finalizes all children")
    func finalizeFinalizesAllChildren() async throws {
        let child1 = MockCaptureOutput(outputID: "c1")
        let child2 = MockCaptureOutput(outputID: "c2")
        let tee = TeeOutput(outputs: [child1, child2])
        try await tee.prepare(audioFormat: nil, videoFormat: nil)
        try await tee.finalize()
        #expect(await child1.finalizeCallCount == 1)
        #expect(await child2.finalizeCallCount == 1)
        #expect(await tee.state == .finalized)
    }

    @Test("addChild increases childCount")
    func addChildIncreasesCount() async {
        let tee = TeeOutput(outputs: [])
        #expect(await tee.childCount == 0)
        await tee.addChild(MockCaptureOutput(outputID: "new"))
        #expect(await tee.childCount == 1)
    }

    @Test("removeChild decreases childCount")
    func removeChildDecreasesCount() async {
        let child = MockCaptureOutput(outputID: "removable")
        let tee = TeeOutput(outputs: [child])
        #expect(await tee.childCount == 1)
        await tee.removeChild("removable")
        #expect(await tee.childCount == 0)
    }

    @Test("removeChild with unknown ID is no-op")
    func removeChildUnknownIsNoOp() async {
        let tee = TeeOutput(outputs: [MockCaptureOutput(outputID: "a")])
        await tee.removeChild("unknown")
        #expect(await tee.childCount == 1)
    }

    @Test("fan-out to 3 outputs")
    func fanOutTo3Outputs() async throws {
        let children: [MockCaptureOutput] = [
            MockCaptureOutput(outputID: "o1"),
            MockCaptureOutput(outputID: "o2"),
            MockCaptureOutput(outputID: "o3")
        ]
        let tee = TeeOutput(outputs: children)
        try await tee.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await tee.receiveAudio(buffer)
        for child in children {
            #expect(await child.receiveAudioCallCount == 1)
        }
    }

    @Test("child prepare failure propagates")
    func childPrepareFailurePropagates() async throws {
        let child = MockCaptureOutput(outputID: "fail")
        await child.setShouldFail(true)
        let tee = TeeOutput(outputs: [child])
        await #expect(throws: CaptureError.self) {
            try await tee.prepare(audioFormat: nil, videoFormat: nil)
        }
    }

    @Test("receiveAudio when not active is no-op")
    func receiveAudioWhenNotActiveIsNoOp() async throws {
        let child = MockCaptureOutput(outputID: "c")
        let tee = TeeOutput(outputs: [child])
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await tee.receiveAudio(buffer)
        #expect(await child.receiveAudioCallCount == 0)
    }

    @Test("generates unique output ID")
    func uniqueOutputID() async {
        let a = TeeOutput(outputs: [])
        let b = TeeOutput(outputs: [])
        let idA = await a.outputID
        let idB = await b.outputID
        #expect(idA != idB)
        #expect(idA.hasPrefix("tee-"))
    }
}
