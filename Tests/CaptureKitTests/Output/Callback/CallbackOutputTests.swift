// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CallbackOutput")
struct CallbackOutputTests {

    @Test("has callback output type")
    func hasCallbackOutputType() {
        let output = CallbackOutput()
        #expect(output.outputType == .callback)
    }

    @Test("starts in idle state")
    func startsInIdleState() async {
        let output = CallbackOutput()
        #expect(await output.state == .idle)
    }

    @Test("prepare transitions to active")
    func prepareTransitionsToActive() async throws {
        let output = CallbackOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        #expect(await output.state == .active)
    }

    @Test("receiveAudio calls audio handler")
    func receiveAudioCallsHandler() async throws {
        let output = CallbackOutput(audioHandler: { _ in })
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        #expect(await output.audioDeliveryCount == 1)
    }

    @Test("receiveVideo calls video handler")
    func receiveVideoCallsHandler() async throws {
        let output = CallbackOutput(videoHandler: { _ in })
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        #expect(await output.videoDeliveryCount == 1)
    }

    @Test("audio delivery count increments")
    func audioDeliveryCountIncrements() async throws {
        let output = CallbackOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        try await output.receiveAudio(buffer)
        #expect(await output.audioDeliveryCount == 2)
    }

    @Test("video delivery count increments")
    func videoDeliveryCountIncrements() async throws {
        let output = CallbackOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        #expect(await output.videoDeliveryCount == 1)
    }

    @Test("nil audio handler is safe")
    func nilAudioHandlerIsSafe() async throws {
        let output = CallbackOutput(audioHandler: nil)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        #expect(await output.audioDeliveryCount == 1)
    }

    @Test("nil video handler is safe")
    func nilVideoHandlerIsSafe() async throws {
        let output = CallbackOutput(videoHandler: nil)
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        #expect(await output.videoDeliveryCount == 1)
    }

    @Test("finalize transitions to finalized")
    func finalizeTransitionsToFinalized() async throws {
        let output = CallbackOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        try await output.finalize()
        #expect(await output.state == .finalized)
    }

    @Test("receiveAudio when not active is no-op")
    func receiveAudioWhenNotActiveIsNoOp() async throws {
        let output = CallbackOutput()
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        #expect(await output.audioDeliveryCount == 0)
    }

    @Test("generates unique output ID")
    func generatesUniqueOutputID() async {
        let a = CallbackOutput()
        let b = CallbackOutput()
        let idA = await a.outputID
        let idB = await b.outputID
        #expect(idA != idB)
        #expect(idA.hasPrefix("callback-"))
    }
}
