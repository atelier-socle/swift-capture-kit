// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("SystemAudioSource with DI", .timeLimit(.minutes(1)))
struct SystemAudioSourceIntegrationTests {

    private func makeSample(
        timestamp: TimeInterval = 0.0
    ) -> CapturedAudioSample {
        CapturedAudioSample(
            data: Data(repeating: 0xBB, count: 128),
            timestamp: timestamp,
            format: AudioFormat(
                sampleRate: .rate48000,
                channelCount: 2,
                channelLayout: .stereo,
                bitDepth: .float32
            )
        )
    }

    @Test("startCapture calls provider startCapture")
    func startCaptureCallsProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let provider = MockScreenCaptureAudioProvider()
        let source = SystemAudioSource(
            audioProvider: provider)
        _ = try await source.startCapture()
        let count = await provider.startCallCount
        #expect(count == 1)
        await source.stopCapture()
    }

    @Test("stopCapture calls provider stopCapture")
    func stopCaptureCallsProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let provider = MockScreenCaptureAudioProvider()
        let source = SystemAudioSource(
            audioProvider: provider)
        _ = try await source.startCapture()
        await source.stopCapture()
        let count = await provider.stopCallCount
        #expect(count == 1)
    }

    @Test("passes capture mode to provider")
    func passesCaptureModeToProvider() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let provider = MockScreenCaptureAudioProvider()
        let source = SystemAudioSource(
            mode: .specificApps(["com.test"]),
            audioProvider: provider
        )
        _ = try await source.startCapture()
        let mode = await provider.lastMode
        #expect(mode == .specificApps(["com.test"]))
        await source.stopCapture()
    }

    @Test("passes excludeOwnApp to provider")
    func passesExcludeOwnApp() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let provider = MockScreenCaptureAudioProvider()
        let source = SystemAudioSource(
            audioProvider: provider)
        _ = try await source.startCapture()
        let exclude = await provider.lastExcludeOwnApp
        #expect(exclude == true)
        await source.stopCapture()
    }

    @Test("produces AudioBuffers from samples")
    func producesAudioBuffers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let provider = MockScreenCaptureAudioProvider()
        await provider.setSyntheticSamples([
            makeSample(timestamp: 0.0),
            makeSample(timestamp: 0.02)
        ])

        let source = SystemAudioSource(
            audioProvider: provider)
        let stream = try await source.startCapture()

        var buffers: [AudioBuffer] = []
        for await buffer in stream {
            buffers.append(buffer)
        }

        #expect(buffers.count == 2)
        #expect(buffers[0].data.count == 128)
        await source.stopCapture()
    }

    @Test("isCapturing toggles correctly")
    func isCapturingToggles() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let provider = MockScreenCaptureAudioProvider()
        let source = SystemAudioSource(
            audioProvider: provider)
        #expect(await source.isCapturing == false)
        _ = try await source.startCapture()
        #expect(await source.isCapturing == true)
        await source.stopCapture()
        #expect(await source.isCapturing == false)
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension MockScreenCaptureAudioProvider {
    func setSyntheticSamples(
        _ samples: [CapturedAudioSample]
    ) {
        self.syntheticSamples = samples
    }
}
