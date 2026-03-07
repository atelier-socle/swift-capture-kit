// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("SampleBufferOutput")
struct SampleBufferOutputTests {

    @Test("has sampleBuffer output type")
    func hasOutputType() {
        let output = SampleBufferOutput()
        #expect(output.outputType == .sampleBuffer)
    }

    @Test("starts in idle state")
    func startsInIdleState() async {
        let output = SampleBufferOutput()
        #expect(await output.state == .idle)
    }

    @Test("prepare transitions to active")
    func prepareToActive() async throws {
        let output = SampleBufferOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        #expect(await output.state == .active)
    }

    @Test("delivery count increments on audio")
    func deliveryCountIncrementsOnAudio() async throws {
        let output = SampleBufferOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        #expect(await output.deliveryCount == 1)
    }

    @Test("delivery count increments on video")
    func deliveryCountIncrementsOnVideo() async throws {
        let output = SampleBufferOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        #expect(await output.deliveryCount == 1)
    }

    @Test("finalize transitions to finalized")
    func finalizeToFinalized() async throws {
        let output = SampleBufferOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        try await output.finalize()
        #expect(await output.state == .finalized)
    }

    @Test("generates unique output ID with prefix")
    func uniqueOutputID() async {
        let output = SampleBufferOutput()
        let id = await output.outputID
        #expect(id.hasPrefix("sample-buffer-"))
    }

    @Test("display name is Sample Buffer Output")
    func displayName() async {
        let output = SampleBufferOutput()
        #expect(await output.displayName == "Sample Buffer Output")
    }
}
