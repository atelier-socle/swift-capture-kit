// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("SilenceSource")
struct SilenceSourceTests {

    @Test("has generator source type")
    func hasGeneratorSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource()
        #expect(await source.sourceType == .generator)
    }

    @Test("generates unique source ID")
    func generatesUniqueSourceID() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let sourceA = SilenceSource()
        let sourceB = SilenceSource()
        let idA = await sourceA.sourceID
        let idB = await sourceB.sourceID
        #expect(idA != idB)
    }

    @Test("is not capturing initially")
    func isNotCapturingInitially() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource()
        #expect(await source.isCapturing == false)
    }

    @Test("has no active format before configure")
    func hasNoActiveFormatBeforeConfigure() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource()
        #expect(await source.activeFormat == nil)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource()
        let config = AudioSourceConfiguration(
            sampleRate: .rate48000,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .float32,
            preferredBufferDuration: 0.01
        )
        try await source.configure(config)
        let format = await source.activeFormat
        #expect(format != nil)
        #expect(format?.sampleRate == .rate48000)
        #expect(format?.channelCount == 2)
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource(
            format: AudioSourceConfiguration(
                sampleRate: .rate48000,
                channelCount: 1,
                channelLayout: .mono,
                bitDepth: .float32,
                preferredBufferDuration: 0.01
            ))
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
        await source.stopCapture()
    }

    @Test("startCapture sets isCapturing to true")
    func startCaptureSetsIsCapturing() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource(
            format: AudioSourceConfiguration(
                sampleRate: .rate48000,
                channelCount: 1,
                channelLayout: .mono,
                bitDepth: .float32,
                preferredBufferDuration: 0.01
            ))
        _ = try await source.startCapture()
        #expect(await source.isCapturing == true)
        await source.stopCapture()
    }

    @Test("startCapture while capturing throws")
    func startCaptureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource(
            format: AudioSourceConfiguration(
                sampleRate: .rate48000,
                channelCount: 1,
                channelLayout: .mono,
                bitDepth: .float32,
                preferredBufferDuration: 0.01
            ))
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
        await source.stopCapture()
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource(
            format: AudioSourceConfiguration(
                sampleRate: .rate48000,
                channelCount: 1,
                channelLayout: .mono,
                bitDepth: .float32,
                preferredBufferDuration: 0.01
            ))
        _ = try await source.startCapture()
        await source.stopCapture()
        #expect(await source.isCapturing == false)
    }

    @Test("produces zero-filled audio buffers")
    func producesZeroFilledBuffers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource(
            format: AudioSourceConfiguration(
                sampleRate: .rate48000,
                channelCount: 1,
                channelLayout: .mono,
                bitDepth: .float32,
                preferredBufferDuration: 0.01
            ))
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let data = try #require(firstBuffer?.data)
        let allZeros = data.allSatisfy { $0 == 0 }
        #expect(allZeros)
    }

    @Test("buffer format matches configuration")
    func bufferFormatMatchesConfiguration() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let config = AudioSourceConfiguration(
            sampleRate: .rate44100,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .float32,
            preferredBufferDuration: 0.01
        )
        let source = SilenceSource(format: config)
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let format = try #require(firstBuffer?.format)
        #expect(format.sampleRate == .rate44100)
        #expect(format.channelCount == 2)
        #expect(format.bitDepth == .float32)
    }

    @Test("buffer duration matches preferredBufferDuration")
    func bufferDurationMatchesPreferred() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let config = AudioSourceConfiguration(
            sampleRate: .rate48000,
            channelCount: 1,
            channelLayout: .mono,
            bitDepth: .float32,
            preferredBufferDuration: 0.01
        )
        let source = SilenceSource(format: config)
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let duration = try #require(firstBuffer?.duration)
        #expect(duration == config.preferredBufferDuration)
    }

    @Test("sequential buffer timestamps increase")
    func sequentialBufferTimestampsIncrease() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource(
            format: AudioSourceConfiguration(
                sampleRate: .rate48000,
                channelCount: 1,
                channelLayout: .mono,
                bitDepth: .float32,
                preferredBufferDuration: 0.01
            ))
        let stream = try await source.startCapture()
        var buffers: [AudioBuffer] = []
        for await buffer in stream {
            buffers.append(buffer)
            if buffers.count >= 2 { break }
        }
        await source.stopCapture()

        #expect(buffers.count == 2)
        #expect(buffers[1].timestamp > buffers[0].timestamp)
    }

    @Test("supports custom sample rate configuration")
    func supportsCustomSampleRate() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let config = AudioSourceConfiguration(
            sampleRate: .rate96000,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .float32,
            preferredBufferDuration: 0.01
        )
        let source = SilenceSource(format: config)
        try await source.configure(config)
        let format = await source.activeFormat
        #expect(format?.sampleRate == .rate96000)
    }

    @Test("availability is available on all platforms")
    func availabilityIsAvailable() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = SilenceSource()
        let availability = source.availability
        #expect(availability.isAvailableOnCurrentPlatform == true)
    }
}
