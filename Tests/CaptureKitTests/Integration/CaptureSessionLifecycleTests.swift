// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CaptureSession Lifecycle Integration")
struct CaptureSessionLifecycleTests {

    // MARK: - Basic Lifecycle

    @Test("audio-only lifecycle: configure, start, capture, stop")
    func audioOnlyLifecycle() async throws {
        let session = CaptureSession()
        let source = MockAudioSource()
        await session.setAudioSource(source)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("video-only lifecycle: configure, start, capture, stop")
    func videoOnlyLifecycle() async throws {
        let session = CaptureSession()
        await session.setVideoSource(MockVideoSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("audio+video lifecycle: full pipeline")
    func audioVideoLifecycle() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        await session.setVideoSource(MockVideoSource())
        await session.setAudioEncoder(MockAudioEncoder())
        await session.setVideoEncoder(MockVideoEncoder())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("start, pause, resume, stop")
    func startPauseResumeStop() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())

        try await session.start()
        #expect(await session.state == .capturing)

        await session.pause()
        #expect(await session.state == .paused)

        try await session.resume()
        #expect(await session.state == .capturing)

        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("start, stop, start again")
    func startStopStartAgain() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())

        try await session.start()
        await session.stop()
        #expect(await session.state == .idle)

        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
    }

    @Test("rapid start/stop cycles")
    func rapidStartStopCycles() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())

        for _ in 0..<5 {
            try await session.start()
            await session.stop()
        }
        #expect(await session.state == .idle)
    }

    // MARK: - Generator Sources

    @Test("SilenceSource to mock output lifecycle")
    func silenceSourceLifecycle() async throws {
        let session = CaptureSession()
        let source = SilenceSource()
        await session.setAudioSource(source)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("ToneSource to mock output lifecycle")
    func toneSourceLifecycle() async throws {
        let session = CaptureSession()
        let source = ToneSource()
        await session.setAudioSource(source)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("BlackSource to mock output lifecycle")
    func blackSourceLifecycle() async throws {
        let session = CaptureSession()
        let source = BlackSource()
        await session.setVideoSource(source)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
        #expect(await session.state == .idle)
    }

    @Test("ColorSource to mock output lifecycle")
    func colorSourceLifecycle() async throws {
        let session = CaptureSession()
        let source = ColorSource(color: .red)
        await session.setVideoSource(source)
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
        #expect(await session.state == .idle)
    }

    // MARK: - Multi-Output

    @Test("two outputs receive same preparation")
    func twoOutputsSamePreparation() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output1 = MockCaptureOutput(outputID: "out-1")
        let output2 = MockCaptureOutput(outputID: "out-2")
        try await session.addOutput(output1)
        try await session.addOutput(output2)
        try await session.start()
        #expect(await output1.prepareCallCount == 1)
        #expect(await output2.prepareCallCount == 1)
        await session.stop()
    }

    @Test("three outputs fan-out")
    func threeOutputsFanOut() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output1 = MockCaptureOutput(outputID: "o1")
        let output2 = MockCaptureOutput(outputID: "o2")
        let output3 = MockCaptureOutput(outputID: "o3")
        try await session.addOutput(output1)
        try await session.addOutput(output2)
        try await session.addOutput(output3)
        try await session.start()
        #expect(await session.outputCount == 3)
        await session.stop()
    }

    @Test("remove one output during capture, others continue")
    func removeOneOutputDuringCapture() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output1 = MockCaptureOutput(outputID: "keep")
        let output2 = MockCaptureOutput(outputID: "remove")
        try await session.addOutput(output1)
        try await session.addOutput(output2)
        try await session.start()
        await session.removeOutput("remove")
        #expect(await session.outputCount == 1)
        #expect(await output2.finalizeCallCount == 1)
        #expect(await session.state == .capturing)
        await session.stop()
    }

    // MARK: - Error Handling

    @Test("output prepare failure stops session")
    func outputPrepareFailureStopsSession() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output = MockCaptureOutput(outputID: "fail")
        await output.setShouldFail(true)
        try await session.addOutput(output)
        await #expect(throws: CaptureError.self) {
            try await session.start()
        }
        #expect(await session.state == .idle)
    }

    // MARK: - Statistics

    @Test("uptime increases over time")
    func uptimeIncreasesOverTime() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()

        for _ in 0..<40 {
            if await session.statistics.uptime > 0 { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(await session.statistics.uptime > 0)
        await session.stop()
    }

    @Test("statistics zero after stop")
    func statisticsZeroAfterStop() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput())
        try await session.start()
        try await Task.sleep(for: .milliseconds(200))
        await session.stop()
        #expect(await session.statistics == .zero)
    }

    // MARK: - Configuration

    @Test("lowLatency configuration applied")
    func lowLatencyConfigurationApplied() async {
        let session = CaptureSession(
            configuration: .lowLatency)
        let config = await session.configuration
        #expect(config.statisticsUpdateInterval == 0.5)
        #expect(config.reconnectOnDeviceDisconnect == false)
    }
}
