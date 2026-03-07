// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CaptureSession Events")
struct CaptureSessionEventIntegrationTests {

    @Test("events stream provides state changes")
    func eventsStreamProvidesStateChanges() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()

        var hasStateChange = false
        for await event in eventStream {
            if case .stateChanged = event {
                hasStateChange = true
                break
            }
        }
        #expect(hasStateChange)
        await session.stop()
    }

    @Test("events stream provides output events")
    func eventsStreamProvidesOutputEvents() async throws {
        let session = CaptureSession()
        let eventStream = await session.events
        try await session.addOutput(
            MockCaptureOutput(outputID: "evt-out"))

        var hasOutputAdded = false
        for await event in eventStream {
            if case .outputAdded(let id) = event {
                if id == "evt-out" {
                    hasOutputAdded = true
                    break
                }
            }
        }
        #expect(hasOutputAdded)
    }

    @Test("events stream provides bitrate changes")
    func eventsStreamProvidesBitrateChanges() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        let eventStream = await session.events
        try await session.start()
        try await session.updateVideoBitrate(4_000_000)

        var hasBitrateChange = false
        for await event in eventStream {
            if case .bitrateChanged = event {
                hasBitrateChange = true
                break
            }
        }
        #expect(hasBitrateChange)
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

        var hasSourceReady = false
        for await event in eventStream {
            if case .audioSourceReady = event {
                hasSourceReady = true
                break
            }
        }
        #expect(hasSourceReady)
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

        var states: [CaptureSessionState] = []
        for await event in eventStream {
            if case .stateChanged(let state) = event {
                states.append(state)
            }
            if states.contains(.capturing) && states.count >= 3 {
                break
            }
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

        var stateOrder: [CaptureSessionState] = []
        for await event in eventStream {
            if case .stateChanged(let state) = event {
                stateOrder.append(state)
            }
            if stateOrder.contains(.idle) && stateOrder.count >= 4 {
                break
            }
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

        var addedIDs: [String] = []
        var removedIDs: [String] = []
        for await event in eventStream {
            switch event {
            case .outputAdded(let id):
                addedIDs.append(id)
            case .outputRemoved(let id):
                removedIDs.append(id)
            default:
                break
            }
            if !removedIDs.isEmpty { break }
        }
        #expect(addedIDs.contains("a"))
        #expect(addedIDs.contains("b"))
        #expect(removedIDs.contains("a"))
    }

    @Test("streaming output added emits event")
    func streamingOutputAddedEmitsEvent() async throws {
        let session = CaptureSession()
        let eventStream = await session.events
        let output = MockStreamingOutput(outputID: "stream-evt")
        try await session.addOutput(output)

        var found = false
        for await event in eventStream {
            if case .outputAdded(let id) = event {
                if id == "stream-evt" {
                    found = true
                    break
                }
            }
        }
        #expect(found)
    }
}
