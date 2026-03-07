// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CaptureSession Dynamic Control")
struct CaptureSessionDynamicControlTests {

    @Test("updateVideoBitrate calls encoder updateBitrate")
    func updateVideoBitrateCallsEncoder() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        let encoder = MockVideoEncoder()
        await session.setVideoEncoder(encoder)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        try await session.updateVideoBitrate(10_000_000)
        #expect(await encoder.updateBitrateCallCount == 1)
        await session.stop()
    }

    @Test("updateVideoBitrate with no encoder is no-op")
    func updateVideoBitrateNoEncoderIsNoOp() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        try await session.updateVideoBitrate(5_000_000)
        await session.stop()
    }

    @Test("forceKeyFrame calls encoder forceKeyFrame")
    func forceKeyFrameCallsEncoder() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        let encoder = MockVideoEncoder()
        await session.setVideoEncoder(encoder)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        try await session.forceKeyFrame()
        #expect(await encoder.forceKeyFrameCallCount == 1)
        await session.stop()
    }

    @Test("forceKeyFrame with no encoder is no-op")
    func forceKeyFrameNoEncoderIsNoOp() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        try await session.forceKeyFrame()
        await session.stop()
    }

    @Test("switchAudioSource replaces source")
    func switchAudioSourceReplacesSource() async throws {
        let session = CaptureSession()
        await session.setAudioSource(
            MockAudioSource(sourceID: "old"))
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        let newSource = MockAudioSource(sourceID: "new")
        try await session.switchAudioSource(newSource)
        let currentID = await session.audioSource?.sourceID
        #expect(currentID == "new")
        await session.stop()
    }

    @Test("switchVideoSource replaces source")
    func switchVideoSourceReplacesSource() async throws {
        let session = CaptureSession()
        await session.setVideoSource(
            MockVideoSource(sourceID: "old"))
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        let newSource = MockVideoSource(sourceID: "new")
        try await session.switchVideoSource(newSource)
        let currentID = await session.videoSource?.sourceID
        #expect(currentID == "new")
        await session.stop()
    }

    @Test("switchAudioSource during pause succeeds")
    func switchAudioSourceDuringPause() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.pause()
        let newSource = MockAudioSource(sourceID: "paused-new")
        try await session.switchAudioSource(newSource)
        let currentID = await session.audioSource?.sourceID
        #expect(currentID == "paused-new")
        await session.stop()
    }

    @Test("switchVideoSource during pause succeeds")
    func switchVideoSourceDuringPause() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.pause()
        let newSource = MockVideoSource(sourceID: "paused-new")
        try await session.switchVideoSource(newSource)
        let currentID = await session.videoSource?.sourceID
        #expect(currentID == "paused-new")
        await session.stop()
    }

    @Test("updateAudioBitrate emits event")
    func updateAudioBitrateEmitsEvent() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        try await session.updateAudioBitrate(256_000)

        var found = false
        for await event in eventStream {
            if case .bitrateChanged(let audio, _) = event {
                if audio == 256_000 {
                    found = true
                    break
                }
            }
        }
        #expect(found)
        await session.stop()
    }

    @Test("updateVideoBitrate emits event")
    func updateVideoBitrateEmitsEvent() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        try await session.updateVideoBitrate(8_000_000)

        var found = false
        for await event in eventStream {
            if case .bitrateChanged(_, let video) = event {
                if video == 8_000_000 {
                    found = true
                    break
                }
            }
        }
        #expect(found)
        await session.stop()
    }

    @Test("multiple bitrate updates in sequence")
    func multipleBitrateUpdatesInSequence() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        let encoder = MockVideoEncoder()
        await session.setVideoEncoder(encoder)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        try await session.updateVideoBitrate(1_000_000)
        try await session.updateVideoBitrate(2_000_000)
        try await session.updateVideoBitrate(3_000_000)
        #expect(await encoder.updateBitrateCallCount == 3)
        await session.stop()
    }

    @Test("switch source then stop cleans up new source")
    func switchSourceThenStopCleansUp() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        let newSource = MockAudioSource(sourceID: "switched")
        try await session.switchAudioSource(newSource)
        await session.stop()
        #expect(await newSource.stopCaptureCallCount >= 1)
    }

    @Test("switch to generator source during capture")
    func switchToGeneratorDuringCapture() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        let toneSource = ToneSource()
        try await session.switchAudioSource(toneSource)
        #expect(await session.state == .capturing)
        await session.stop()
    }

    @Test("bitrate update during pause throws")
    func bitrateUpdateDuringPauseThrows() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.pause()
        await #expect(throws: CaptureError.self) {
            try await session.updateVideoBitrate(5_000_000)
        }
        await session.stop()
    }
}
