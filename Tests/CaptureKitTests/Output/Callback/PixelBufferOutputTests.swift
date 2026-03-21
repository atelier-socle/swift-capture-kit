// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PixelBufferOutput", .timeLimit(.minutes(1)))
struct PixelBufferOutputTests {

    @Test("has pixelBuffer output type")
    func hasOutputType() {
        let output = PixelBufferOutput { _ in }
        #expect(output.outputType == .pixelBuffer)
    }

    @Test("starts in idle state")
    func startsInIdleState() async {
        let output = PixelBufferOutput { _ in }
        #expect(await output.state == .idle)
    }

    @Test("prepare transitions to active")
    func prepareToActive() async throws {
        let output = PixelBufferOutput { _ in }
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        #expect(await output.state == .active)
    }

    @Test("receiveVideo calls handler and increments count")
    func receiveVideoCallsHandler() async throws {
        let output = PixelBufferOutput { _ in }
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        #expect(await output.deliveryCount == 1)
    }

    @Test("receiveAudio is no-op")
    func receiveAudioIsNoOp() async throws {
        let output = PixelBufferOutput { _ in }
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        #expect(await output.deliveryCount == 0)
    }

    @Test("finalize transitions to finalized")
    func finalizeToFinalized() async throws {
        let output = PixelBufferOutput { _ in }
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        try await output.finalize()
        #expect(await output.state == .finalized)
    }

    @Test("generates unique output ID with prefix")
    func uniqueOutputID() async {
        let output = PixelBufferOutput { _ in }
        let id = await output.outputID
        #expect(id.hasPrefix("pixel-buffer-"))
    }

    @Test("display name is Pixel Buffer Output")
    func displayName() async {
        let output = PixelBufferOutput { _ in }
        #expect(await output.displayName == "Pixel Buffer Output")
    }
}
