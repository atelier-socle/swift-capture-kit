// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("NullOutput", .timeLimit(.minutes(1)))
struct NullOutputTests {

    @Test("has null output type")
    func hasNullOutputType() {
        let output = NullOutput()
        #expect(output.outputType == .null)
    }

    @Test("starts in idle state")
    func startsInIdleState() async {
        let output = NullOutput()
        #expect(await output.state == .idle)
    }

    @Test("prepare transitions to active")
    func prepareToActive() async throws {
        let output = NullOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        #expect(await output.state == .active)
    }

    @Test("receiveAudio increments discard count")
    func receiveAudioIncrementsCount() async throws {
        let output = NullOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        try await output.receiveAudio(buffer)
        #expect(await output.discardedAudioCount == 2)
    }

    @Test("receiveVideo increments discard count")
    func receiveVideoIncrementsCount() async throws {
        let output = NullOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        #expect(await output.discardedVideoCount == 1)
    }

    @Test("finalize transitions to finalized")
    func finalizeToFinalized() async throws {
        let output = NullOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        try await output.finalize()
        #expect(await output.state == .finalized)
    }

    @Test("discarded counts start at zero")
    func countsStartAtZero() async {
        let output = NullOutput()
        #expect(await output.discardedAudioCount == 0)
        #expect(await output.discardedVideoCount == 0)
    }

    @Test("display name is Null Output")
    func displayName() async {
        let output = NullOutput()
        #expect(await output.displayName == "Null Output")
    }

    @Test("generates unique output ID")
    func uniqueOutputID() async {
        let a = NullOutput()
        let b = NullOutput()
        let idA = await a.outputID
        let idB = await b.outputID
        #expect(idA != idB)
        #expect(idA.hasPrefix("null-"))
    }
}
