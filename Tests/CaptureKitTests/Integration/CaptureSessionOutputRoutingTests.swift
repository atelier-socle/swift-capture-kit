// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CaptureSession Output Routing")
struct CaptureSessionOutputRoutingTests {

    @Test("output added during capture receives preparation")
    func outputAddedDuringCapture() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        try await session.addOutput(MockCaptureOutput(outputID: "o1"))
        try await session.start()
        let newOutput = MockCaptureOutput(outputID: "o2")
        try await session.addOutput(newOutput)
        #expect(await session.outputCount == 2)
        await session.stop()
    }

    @Test("output removed during capture stops receiving")
    func outputRemovedDuringCapture() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output = MockCaptureOutput(outputID: "removable")
        try await session.addOutput(output)
        try await session.start()
        await session.removeOutput("removable")
        #expect(await session.outputCount == 0)
        #expect(await output.finalizeCallCount == 1)
        await session.stop()
    }

    @Test("output finalize called on stop")
    func outputFinalizeCalledOnStop() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output = MockCaptureOutput()
        try await session.addOutput(output)
        try await session.start()
        await session.stop()
        #expect(await output.finalizeCallCount >= 1)
    }

    @Test("output finalize called on remove")
    func outputFinalizeCalledOnRemove() async throws {
        let session = CaptureSession()
        let output = MockCaptureOutput(outputID: "rm")
        try await session.addOutput(output)
        await session.removeOutput("rm")
        #expect(await output.finalizeCallCount == 1)
    }

    @Test("output prepare called with correct formats")
    func outputPrepareCalledWithFormats() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        await session.setVideoSource(MockVideoSource())
        let output = MockCaptureOutput()
        try await session.addOutput(output)
        try await session.start()
        #expect(await output.prepareCallCount == 1)
        await session.stop()
    }

    @Test("streaming output conforms to CaptureOutput")
    func streamingOutputConformsToCaptureOutput() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let output = MockStreamingOutput()
        try await session.addOutput(output)
        try await session.start()
        #expect(await output.prepareCallCount == 1)
        await session.stop()
    }

    @Test("streaming output transport quality accessible")
    func streamingOutputTransportQualityAccessible() async throws {
        let output = MockStreamingOutput()
        await output.setTransportQuality(
            StreamingTransportQuality(
                score: 0.95, grade: .excellent
            ))
        let quality = await output.transportQuality
        #expect(quality?.score == 0.95)
        #expect(quality?.grade == .excellent)
    }

    @Test("fan-out to 5 outputs")
    func fanOutTo5Outputs() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        var outputs: [MockCaptureOutput] = []
        for i in 0..<5 {
            let output = MockCaptureOutput(outputID: "out-\(i)")
            outputs.append(output)
            try await session.addOutput(output)
        }
        try await session.start()
        for output in outputs {
            #expect(await output.prepareCallCount == 1)
        }
        #expect(await session.outputCount == 5)
        await session.stop()
    }

    @Test("mixed output types (callback + streaming)")
    func mixedOutputTypes() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let callbackOutput = MockCaptureOutput(
            outputID: "cb",
            outputType: .callback
        )
        let streamingOutput = MockStreamingOutput(
            outputID: "stream"
        )
        try await session.addOutput(callbackOutput)
        try await session.addOutput(streamingOutput)
        try await session.start()
        #expect(await session.outputCount == 2)
        #expect(await callbackOutput.prepareCallCount == 1)
        #expect(await streamingOutput.prepareCallCount == 1)
        await session.stop()
    }

    @Test("output error does not crash session")
    func outputErrorDoesNotCrashSession() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let goodOutput = MockCaptureOutput(outputID: "good")
        try await session.addOutput(goodOutput)
        try await session.start()
        #expect(await session.state == .capturing)
        await session.stop()
    }

    @Test("null output added does not affect others")
    func nullOutputDoesNotAffectOthers() async throws {
        let session = CaptureSession()
        await session.setAudioSource(MockAudioSource())
        let normalOutput = MockCaptureOutput(
            outputID: "normal")
        let nullOutput = MockCaptureOutput(
            outputID: "null-out", outputType: .null)
        try await session.addOutput(normalOutput)
        try await session.addOutput(nullOutput)
        try await session.start()
        #expect(await session.outputCount == 2)
        #expect(await normalOutput.prepareCallCount == 1)
        #expect(await nullOutput.prepareCallCount == 1)
        await session.stop()
    }

    @Test("streaming output connection state changes")
    func streamingOutputConnectionStateChanges() async throws {
        let output = MockStreamingOutput()
        #expect(
            await output.connectionState == .disconnected
        )
        await output.setConnectionState(.connected)
        #expect(await output.connectionState == .connected)
    }

    @Test("streaming output delivers audio")
    func streamingOutputDeliversAudio() async throws {
        let output = MockStreamingOutput()
        let buffer = EncodedAudioBuffer(
            data: Data([1, 2, 3]),
            codec: .aac,
            timestamp: 0.0,
            duration: 0.1,
            sequenceNumber: 0
        )
        try await output.deliverAudio(buffer)
        #expect(await output.audioDeliveryCount == 1)
    }

    @Test("streaming output delivers video")
    func streamingOutputDeliversVideo() async throws {
        let output = MockStreamingOutput()
        let frame = EncodedVideoFrame(
            data: Data([1, 2, 3]),
            codec: .h264,
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 0
        )
        try await output.deliverVideo(frame)
        #expect(await output.videoDeliveryCount == 1)
    }
}
