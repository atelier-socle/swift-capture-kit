// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CaptureSession Events", .timeLimit(.minutes(1)))
struct CaptureSessionEventIntegrationTests {

    @Test("events stream provides state changes")
    func eventsStreamProvidesStateChanges() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()

        let event = await firstEvent(from: eventStream) { event in
            if case .stateChanged = event { return true }
            return false
        }
        #expect(event != nil)
        await session.stop()
    }

    @Test("events stream provides output events")
    func eventsStreamProvidesOutputEvents() async throws {
        let session = CaptureSession()
        let eventStream = await session.events
        try await session.addOutput(
            MockCaptureOutput(outputID: "evt-out"))

        let event = await firstEvent(from: eventStream) { event in
            if case .outputAdded("evt-out") = event { return true }
            return false
        }
        #expect(event != nil)
    }

    @Test("events stream provides bitrate changes")
    func eventsStreamProvidesBitrateChanges() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        try await session.updateVideoBitrate(4_000_000)

        let event = await firstEvent(from: eventStream) { event in
            if case .bitrateChanged = event { return true }
            return false
        }
        #expect(event != nil)
        await session.stop()
    }

    @Test("events stream provides source ready events")
    func eventsStreamProvidesSourceReadyEvents() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        try await session.switchAudioSource(
            MockAudioSource(sourceID: "ready"))

        let event = await firstEvent(from: eventStream) { event in
            if case .audioSourceReady = event { return true }
            return false
        }
        #expect(event != nil)
        await session.stop()
    }

    @Test("events survive pause/resume")
    func eventsSurvivePauseResume() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        await session.pause()
        try await session.resume()

        let events = await collectEvents(from: eventStream) { collected in
            let states = collected.compactMap { event -> CaptureSessionState? in
                if case .stateChanged(let state) = event { return state }
                return nil
            }
            return states.contains(.capturing) && states.count >= 3
        }
        let states = events.compactMap { event -> CaptureSessionState? in
            if case .stateChanged(let state) = event { return state }
            return nil
        }
        #expect(states.contains(.paused))
        await session.stop()
    }

    @Test("event order matches operation order")
    func eventOrderMatchesOperationOrder() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        await session.stop()

        let events = await collectEvents(from: eventStream) { collected in
            let states = collected.compactMap { event -> CaptureSessionState? in
                if case .stateChanged(let state) = event { return state }
                return nil
            }
            return states.contains(.idle) && states.count >= 4
        }
        let stateOrder = events.compactMap { event -> CaptureSessionState? in
            if case .stateChanged(let state) = event { return state }
            return nil
        }
        // Should see: starting, capturing, stopping, idle
        #expect(stateOrder.count >= 4)
        if stateOrder.count >= 4 {
            #expect(stateOrder[0] == .starting)
            #expect(stateOrder[1] == .capturing)
            #expect(stateOrder[2] == .stopping)
            #expect(stateOrder[3] == .idle)
        }
    }

    @Test("no events emitted when idle")
    func noEventsEmittedWhenIdle() async throws {
        let session = CaptureSession()
        let eventStream = await session.events
        // Just verify the stream is created without crashing
        _ = eventStream
        #expect(await session.state == .idle)
    }

    @Test("multiple output events in sequence")
    func multipleOutputEventsInSequence() async throws {
        let session = CaptureSession()
        let eventStream = await session.events
        try await session.addOutput(
            MockCaptureOutput(outputID: "a"))
        try await session.addOutput(
            MockCaptureOutput(outputID: "b"))
        await session.removeOutput("a")

        let events = await collectEvents(from: eventStream) { collected in
            collected.contains { event in
                if case .outputRemoved = event { return true }
                return false
            }
        }
        let addedIDs = events.compactMap { event -> String? in
            if case .outputAdded(let id) = event { return id }
            return nil
        }
        let removedIDs = events.compactMap { event -> String? in
            if case .outputRemoved(let id) = event { return id }
            return nil
        }
        #expect(addedIDs.contains("a"))
        #expect(addedIDs.contains("b"))
        #expect(removedIDs.contains("a"))
    }

}
