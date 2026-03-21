// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CaptureSession", .timeLimit(.minutes(1)))
struct CaptureSessionTests {

    // MARK: - Initialization

    @Test("initializes with idle state")
    func initializesWithIdleState() async {
        let session = CaptureSession()
        #expect(await session.state == .idle)
    }

    @Test("initializes with default configuration")
    func initializesWithDefaultConfiguration() async {
        let session = CaptureSession()
        #expect(
            await session.configuration
                == CaptureSessionConfiguration.default
        )
    }

    @Test("initializes with custom configuration")
    func initializesWithCustomConfiguration() async {
        let config = CaptureSessionConfiguration.lowLatency
        let session = CaptureSession(configuration: config)
        #expect(await session.configuration == config)
    }

    @Test("statistics are zero initially")
    func statisticsAreZeroInitially() async {
        let session = CaptureSession()
        #expect(await session.statistics == .zero)
    }

    // MARK: - Output Management

    @Test("addOutput increases output count")
    func addOutputIncreasesOutputCount() async throws {
        let session = CaptureSession()
        let output = MockCaptureOutput()
        try await session.addOutput(output)
        #expect(await session.outputCount == 1)
    }

    @Test("addOutput with multiple outputs")
    func addOutputWithMultipleOutputs() async throws {
        let session = CaptureSession()
        try await session.addOutput(
            MockCaptureOutput(outputID: "out-1"))
        try await session.addOutput(
            MockCaptureOutput(outputID: "out-2"))
        try await session.addOutput(
            MockCaptureOutput(outputID: "out-3"))
        #expect(await session.outputCount == 3)
    }

    @Test("removeOutput decreases output count")
    func removeOutputDecreasesOutputCount() async throws {
        let session = CaptureSession()
        let output = MockCaptureOutput(outputID: "removable")
        try await session.addOutput(output)
        #expect(await session.outputCount == 1)
        await session.removeOutput("removable")
        #expect(await session.outputCount == 0)
    }

    @Test("removeOutput with unknown ID is no-op")
    func removeOutputUnknownIDIsNoOp() async throws {
        let session = CaptureSession()
        try await session.addOutput(MockCaptureOutput(outputID: "a"))
        await session.removeOutput("unknown-id")
        #expect(await session.outputCount == 1)
    }

    @Test("removeOutput finalizes the output")
    func removeOutputFinalizesTheOutput() async throws {
        let session = CaptureSession()
        let output = MockCaptureOutput(outputID: "to-finalize")
        try await session.addOutput(output)
        await session.removeOutput("to-finalize")
        #expect(await output.finalizeCallCount == 1)
    }

    // MARK: - Start Validation

    @Test("start without sources throws sessionNotConfigured")
    func startWithoutSourcesThrows() async throws {
        let session = CaptureSession()
        try await session.addOutput(MockCaptureOutput())
        await #expect(throws: CaptureError.self) {
            try await session.start()
        }
    }

    @Test("start without outputs throws invalidConfiguration")
    func startWithoutOutputsThrows() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        await #expect(throws: CaptureError.self) {
            try await session.start()
        }
    }

    @Test("start with audio source only succeeds")
    func startWithAudioSourceOnlySucceeds() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
    }

    @Test("start with video source only succeeds")
    func startWithVideoSourceOnlySucceeds() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
    }

    @Test("start with both sources succeeds")
    func startWithBothSourcesSucceeds() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
    }

    @Test("start when already running throws sessionAlreadyRunning")
    func startWhenAlreadyRunningThrows() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await #expect(throws: CaptureError.self) {
            try await session.start()
        }
        await session.stop()
    }

    @Test("start prepares all outputs")
    func startPreparesAllOutputs() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output1 = MockCaptureOutput(outputID: "o1")
        let output2 = MockCaptureOutput(outputID: "o2")
        try await session.addOutput(output1)
        try await session.addOutput(output2)
        try await session.start()
        #expect(await output1.prepareCallCount == 1)
        #expect(await output2.prepareCallCount == 1)
        await session.stop()
    }

    // MARK: - State Machine

    @Test("idle is initial state")
    func idleIsInitialState() async {
        let session = CaptureSession()
        #expect(await session.state == .idle)
    }

    @Test("start transitions to capturing")
    func startTransitionsToCapturing() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
    }

    @Test("pause transitions to paused")
    func pauseTransitionsToPaused() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.pause()
        #expect(await session.state == .paused)
        await session.stop()
    }

    @Test("pause when not capturing is no-op")
    func pauseWhenNotCapturingIsNoOp() async {
        let session = CaptureSession()
        await session.pause()
        #expect(await session.state == .idle)
    }

    @Test("resume transitions from paused to capturing")
    func resumeTransitionsFromPausedToCapturing() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.pause()
        try await session.resume()
        #expect(await session.state == .capturing)
        await session.stop()
    }

    @Test("resume when not paused throws")
    func resumeWhenNotPausedThrows() async {
        let session = CaptureSession()
        await #expect(throws: CaptureError.self) {
            try await session.resume()
        }
    }

    @Test("stop transitions to idle")
    func stopTransitionsToIdle() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("stop when idle is no-op")
    func stopWhenIdleIsNoOp() async {
        let session = CaptureSession()
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("stop cancels capture task")
    func stopCancelsCaptureTask() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("stop stops audio source")
    func stopStopsAudioSource() async throws {
        let session = CaptureSession()
        let source = MockAudioSource()
        await session.setAudioSource(source)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.stop()
        #expect(await source.stopCaptureCallCount >= 1)
    }

    @Test("stop stops video source")
    func stopStopsVideoSource() async throws {
        let session = CaptureSession()
        let source = MockVideoSource()
        await session.setVideoSource(source)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.stop()
        #expect(await source.stopCaptureCallCount >= 1)
    }

    @Test("stop flushes encoders")
    func stopFlushesEncoders() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let audioEncoder = MockAudioEncoder()
        let videoEncoder = MockVideoEncoder()
        await session.setAudioEncoder(audioEncoder)
        await session.setVideoEncoder(videoEncoder)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.stop()
        #expect(await audioEncoder.flushCallCount >= 1)
        #expect(await videoEncoder.flushCallCount >= 1)
    }

    @Test("stop finalizes all outputs")
    func stopFinalizesAllOutputs() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output1 = MockCaptureOutput(outputID: "o1")
        let output2 = MockCaptureOutput(outputID: "o2")
        try await session.addOutput(output1)
        try await session.addOutput(output2)
        try await session.start()
        await session.stop()
        #expect(await output1.finalizeCallCount >= 1)
        #expect(await output2.finalizeCallCount >= 1)
    }

}

// MARK: - Helper Extensions

extension CaptureSession {
    /// Test helper to set the audio source.
    func setAudioSource(_ source: any AudioSource) {
        self.audioSource = source
    }

    /// Test helper to set the video source.
    func setVideoSource(_ source: any VideoSource) {
        self.videoSource = source
    }

    /// Test helper to set the audio encoder.
    func setAudioEncoder(_ encoder: any AudioEncoderProtocol) {
        self.audioEncoder = encoder
    }

    /// Test helper to set the video encoder.
    func setVideoEncoder(_ encoder: any VideoEncoderProtocol) {
        self.videoEncoder = encoder
    }
}

extension MockCaptureOutput {
    /// Test helper to set shouldFailOnPrepare.
    func setShouldFail(_ shouldFail: Bool) {
        self.shouldFailOnPrepare = shouldFail
    }
}
