// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("MicrophoneSource with DI", .timeLimit(.minutes(1)))
struct MicrophoneSourceIntegrationTests {

    private func makeSample(
        timestamp: TimeInterval = 0.0
    ) -> CapturedAudioSample {
        CapturedAudioSample(
            data: Data(repeating: 0x42, count: 256),
            timestamp: timestamp,
            format: AudioFormat(
                sampleRate: .rate48000,
                channelCount: 2,
                channelLayout: .stereo,
                bitDepth: .float32
            )
        )
    }

    @Test("startCapture calls engine startCapture")
    func startCaptureCallsEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        let source = MicrophoneSource(captureEngine: engine)
        _ = try await source.startCapture()
        let count = await engine.startCallCount
        #expect(count == 1)
        await source.stopCapture()
    }

    @Test("stopCapture calls engine stopCapture")
    func stopCaptureCallsEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        let source = MicrophoneSource(captureEngine: engine)
        _ = try await source.startCapture()
        await source.stopCapture()
        let count = await engine.stopCallCount
        #expect(count == 1)
    }

    @Test("produces AudioBuffer from CapturedAudioSample")
    func producesAudioBuffer() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        await engine.setSyntheticSamples([makeSample()])

        let source = MicrophoneSource(captureEngine: engine)
        let stream = try await source.startCapture()

        var buffers: [AudioBuffer] = []
        for await buffer in stream {
            buffers.append(buffer)
        }

        #expect(buffers.count == 1)
        #expect(buffers.first?.data.count == 256)
        await source.stopCapture()
    }

    @Test("passes device ID to engine")
    func passesDeviceID() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let device = AudioDeviceInfo(
            id: "test-mic-123",
            name: "Test Mic",
            manufacturer: "Test",
            connectionType: .usb,
            inputChannelCount: 2,
            supportedSampleRates: [.rate48000]
        )
        let engine = MockAudioCaptureEngine()
        let source = MicrophoneSource(
            device: device, captureEngine: engine)
        _ = try await source.startCapture()
        let deviceID = await engine.lastDeviceID
        #expect(deviceID == "test-mic-123")
        await source.stopCapture()
    }

    @Test("AGC flag is stored correctly")
    func agcFlagStored() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        let source = MicrophoneSource(captureEngine: engine)
        let agc = await source.automaticGainControl
        #expect(agc == true)
    }

    @Test("echo cancellation flag is stored correctly")
    func echoCancellationFlagStored() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        let source = MicrophoneSource(captureEngine: engine)
        let ec = await source.echoCancellation
        #expect(ec == false)
    }

    @Test("sequential buffers have incrementing sequence numbers")
    func sequentialBuffers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        await engine.setSyntheticSamples([
            makeSample(timestamp: 0.0),
            makeSample(timestamp: 0.02),
            makeSample(timestamp: 0.04)
        ])

        let source = MicrophoneSource(captureEngine: engine)
        let stream = try await source.startCapture()

        var sequences: [Int64] = []
        for await buffer in stream {
            sequences.append(buffer.sequenceNumber)
        }

        #expect(sequences == [0, 1, 2])
        await source.stopCapture()
    }

    @Test("isCapturing reflects engine state")
    func isCapturingReflectsState() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        let source = MicrophoneSource(captureEngine: engine)
        #expect(await source.isCapturing == false)

        _ = try await source.startCapture()
        #expect(await source.isCapturing == true)

        await source.stopCapture()
        #expect(await source.isCapturing == false)
    }

    @Test("startCapture twice throws")
    func startCaptureTwiceThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        let source = MicrophoneSource(captureEngine: engine)
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
        await source.stopCapture()
    }

    @Test("configure passes through to active format")
    func configurePassesThrough() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        let source = MicrophoneSource(captureEngine: engine)
        let config = AudioSourceConfiguration(
            sampleRate: .rate44100,
            channelCount: 1,
            channelLayout: .mono
        )
        try await source.configure(config)
        let format = await source.activeFormat
        #expect(format?.sampleRate == .rate44100)
        #expect(format?.channelCount == 1)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension MockAudioCaptureEngine {
    func setSyntheticSamples(
        _ samples: [CapturedAudioSample]
    ) {
        self.syntheticSamples = samples
    }
}
