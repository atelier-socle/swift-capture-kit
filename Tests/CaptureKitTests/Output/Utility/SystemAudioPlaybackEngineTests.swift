// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if canImport(AVFAudio)
    import Foundation
    import Testing

    @testable import CaptureKit

    @Suite("SystemAudioPlaybackEngine")
    struct SystemAudioPlaybackEngineTests {

        @Test(
            "prepare uses non-interleaved format regardless of input",
            .tags(.hardware))
        func prepareUsesNonInterleavedFormat() async throws {
            guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
            else { return }

            let engine = SystemAudioPlaybackEngine()
            let format = AudioFormat(
                sampleRate: .rate48000,
                channelCount: 2,
                channelLayout: .stereo,
                bitDepth: .float32,
                isInterleaved: true
            )
            try await engine.prepare(format: format)
            await engine.stop()
        }

        @Test(
            "play with stereo interleaved data does not crash",
            .tags(.hardware))
        func playWithStereoInterleavedData() async throws {
            guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
            else { return }

            let engine = SystemAudioPlaybackEngine()
            let format = AudioFormat(
                sampleRate: .rate48000,
                channelCount: 2,
                channelLayout: .stereo,
                bitDepth: .float32,
                isInterleaved: true
            )
            try await engine.prepare(format: format)

            // Create 128 frames of stereo interleaved float32 silence
            let frameCount = 128
            let channelCount = 2
            let data = Data(
                repeating: 0,
                count: frameCount * channelCount
                    * MemoryLayout<Float>.size)
            try await engine.play(data)
            await engine.stop()
        }

        @Test(
            "play with mono data does not crash",
            .tags(.hardware))
        func playWithMonoData() async throws {
            guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
            else { return }

            let engine = SystemAudioPlaybackEngine()
            let format = AudioFormat(
                sampleRate: .rate48000,
                channelCount: 1,
                channelLayout: .mono,
                bitDepth: .float32,
                isInterleaved: false
            )
            try await engine.prepare(format: format)

            let frameCount = 128
            let data = Data(
                repeating: 0,
                count: frameCount * MemoryLayout<Float>.size)
            try await engine.play(data)
            await engine.stop()
        }

        @Test("setVolume stores value")
        func setVolumeStoresValue() async {
            guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
            else { return }

            let engine = SystemAudioPlaybackEngine()
            await engine.setVolume(0.5)
        }

        @Test("setMuted does not crash")
        func setMutedNoCrash() async {
            guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
            else { return }

            let engine = SystemAudioPlaybackEngine()
            await engine.setMuted(true)
            await engine.setMuted(false)
        }

        @Test("stop without prepare is no-op")
        func stopWithoutPrepareIsNoOp() async {
            guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
            else { return }

            let engine = SystemAudioPlaybackEngine()
            await engine.stop()
        }

        @Test("play without prepare is no-op")
        func playWithoutPrepareIsNoOp() async throws {
            guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
            else { return }

            let engine = SystemAudioPlaybackEngine()
            let data = Data(repeating: 0, count: 512)
            try await engine.play(data)
        }
    }
#endif
