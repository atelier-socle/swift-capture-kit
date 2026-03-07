// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AudioPreviewOutput")
struct AudioPreviewOutputTests {

    @Test("has audioPreview output type")
    func hasAudioPreviewOutputType() {
        let output = AudioPreviewOutput()
        #expect(output.outputType == .audioPreview)
    }

    @Test("default volume is 1.0")
    func defaultVolumeIs1() async {
        let output = AudioPreviewOutput()
        #expect(await output.volume == 1.0)
    }

    @Test("volume clamped to 0.0-1.0 range")
    func volumeClampedHigh() async {
        let output = AudioPreviewOutput(volume: 2.0)
        #expect(await output.volume == 1.0)
    }

    @Test("volume clamped low")
    func volumeClampedLow() async {
        let output = AudioPreviewOutput(volume: -1.0)
        #expect(await output.volume == 0.0)
    }

    @Test("isMuted default is false")
    func isMutedDefaultIsFalse() async {
        let output = AudioPreviewOutput()
        #expect(await output.isMuted == false)
    }

    @Test("receiveAudio when muted is no-op")
    func receiveAudioWhenMutedIsNoOp() async throws {
        let output = AudioPreviewOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        await output.setMuted(true)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        #expect(await output.buffersMonitored == 0)
    }

    @Test("receiveAudio increments buffersMonitored")
    func receiveAudioIncrementsCount() async throws {
        let output = AudioPreviewOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        try await output.receiveAudio(buffer)
        #expect(await output.buffersMonitored == 2)
    }

    @Test("receiveVideo is no-op")
    func receiveVideoIsNoOp() async throws {
        let output = AudioPreviewOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        #expect(await output.buffersMonitored == 0)
    }

    @Test("finalize transitions to finalized")
    func finalizeToFinalized() async throws {
        let output = AudioPreviewOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        try await output.finalize()
        #expect(await output.state == .finalized)
    }

    @Test("generates unique output ID")
    func uniqueOutputID() async {
        let output = AudioPreviewOutput()
        let id = await output.outputID
        #expect(id.hasPrefix("audio-preview-"))
    }
}

extension AudioPreviewOutput {
    /// Test helper to set muted state.
    func setMuted(_ muted: Bool) {
        self.isMuted = muted
    }
}
