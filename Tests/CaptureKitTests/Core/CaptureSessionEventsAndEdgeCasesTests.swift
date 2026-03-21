// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CaptureSession Events & Edge Cases", .timeLimit(.minutes(1)))
struct CaptureSessionEventsAndEdgeCasesTests {

    // MARK: - Events

    @Test("emits stateChanged on start")
    func emitsStateChangedOnStart() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()

        let events = await collectEvents(from: eventStream) { collected in
            collected.contains { event in
                if case .stateChanged(.capturing) = event { return true }
                return false
            }
        }
        let states = events.compactMap { event -> CaptureSessionState? in
            if case .stateChanged(let state) = event { return state }
            return nil
        }
        #expect(states.contains(.starting))
        #expect(states.contains(.capturing))
        await session.stop()
    }

    @Test("emits stateChanged on stop")
    func emitsStateChangedOnStop() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        await session.stop()

        let events = await collectEvents(from: eventStream) { collected in
            collected.contains { event in
                if case .stateChanged(.idle) = event { return true }
                return false
            }
        }
        let states = events.compactMap { event -> CaptureSessionState? in
            if case .stateChanged(let state) = event { return state }
            return nil
        }
        #expect(states.contains(.idle))
    }

    @Test("emits outputAdded on addOutput")
    func emitsOutputAddedOnAddOutput() async throws {
        let session = CaptureSession()
        let eventStream = await session.events
        try await session.addOutput(
            MockCaptureOutput(outputID: "test-out"))

        let event = await firstEvent(from: eventStream) { event in
            if case .outputAdded("test-out") = event { return true }
            return false
        }
        #expect(event != nil)
    }

    @Test("emits outputRemoved on removeOutput")
    func emitsOutputRemovedOnRemoveOutput() async throws {
        let session = CaptureSession()
        let eventStream = await session.events
        try await session.addOutput(
            MockCaptureOutput(outputID: "rm-out"))
        await session.removeOutput("rm-out")

        let event = await firstEvent(from: eventStream) { event in
            if case .outputRemoved("rm-out") = event { return true }
            return false
        }
        #expect(event != nil)
    }

    @Test("emits bitrateChanged on updateVideoBitrate")
    func emitsBitrateChangedOnUpdateVideoBitrate() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        await session.setVideoEncoder(MockVideoEncoder())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        try await session.updateVideoBitrate(8_000_000)

        let event = await firstEvent(from: eventStream) { event in
            if case .bitrateChanged(_, 8_000_000) = event { return true }
            return false
        }
        #expect(event != nil)
        await session.stop()
    }

    @Test("emits audioSourceReady on switchAudioSource")
    func emitsAudioSourceReadyOnSwitch() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        try await session.switchAudioSource(
            MockAudioSource(sourceID: "switched"))

        let event = await firstEvent(from: eventStream) { event in
            if case .audioSourceReady("switched") = event { return true }
            return false
        }
        #expect(event != nil)
        await session.stop()
    }

    @Test("emits videoSourceReady on switchVideoSource")
    func emitsVideoSourceReadyOnSwitch() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        try await session.switchVideoSource(
            MockVideoSource(sourceID: "switched"))

        let event = await firstEvent(from: eventStream) { event in
            if case .videoSourceReady("switched") = event { return true }
            return false
        }
        #expect(event != nil)
        await session.stop()
    }

    // MARK: - Statistics

    @Test("statistics uptime increases during capture")
    func statisticsUptimeIncreasesDuringCapture() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()

        for _ in 0..<40 {
            if await session.statistics.uptime > 0 { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        let uptime = await session.statistics.uptime
        #expect(uptime > 0)
        await session.stop()
    }

    @Test("statistics are reset on stop")
    func statisticsAreResetOnStop() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        try await Task.sleep(for: .milliseconds(200))
        await session.stop()
        #expect(await session.statistics == .zero)
    }

    // MARK: - Configured Preset

    @Test("configured with preset returns session")
    func configuredWithPresetReturnsSession() async {
        let session = CaptureSession.configured(with: CapturePreset.twitch())
        #expect(await session.state == .idle)
    }

    @Test("configured session is in idle state")
    func configuredSessionIsInIdleState() async {
        let session = CaptureSession.configured(
            with: CapturePreset.podcastAudioHQ())
        #expect(await session.state == .idle)
    }

    // MARK: - Edge Cases

    @Test("multiple start calls throw after first")
    func multipleStartCallsThrowAfterFirst() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await #expect(throws: CaptureError.self) {
            try await session.start()
        }
        await session.stop()
    }

    @Test("stop after pause works")
    func stopAfterPauseWorks() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        await session.pause()
        #expect(await session.state == .paused)
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("addOutput during capture works")
    func addOutputDuringCaptureWorks() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(
            MockCaptureOutput(outputID: "o1"))
        try await session.start()
        try await session.addOutput(
            MockCaptureOutput(outputID: "o2"))
        #expect(await session.outputCount == 2)
        await session.stop()
    }

    @Test("removeOutput during capture works")
    func removeOutputDuringCaptureWorks() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(
            MockCaptureOutput(outputID: "o1"))
        try await session.addOutput(
            MockCaptureOutput(outputID: "o2"))
        try await session.start()
        await session.removeOutput("o1")
        #expect(await session.outputCount == 1)
        await session.stop()
    }

    @Test("start with failing output throws")
    func startWithFailingOutputThrows() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output = MockCaptureOutput(outputID: "fail-out")
        await output.setShouldFail(true)
        try await session.addOutput(output)
        await #expect(throws: CaptureError.self) {
            try await session.start()
        }
        #expect(await session.state == .idle)
    }
}
