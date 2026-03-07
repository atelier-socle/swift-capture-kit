// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("AudioSource")
struct AudioSourceTests {

    @Test("MockAudioSource conforms to AudioSource protocol")
    func mockConformsToProtocol() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MockAudioSource()
        #expect(source.sourceID == "mock-audio")
        #expect(source.displayName == "Mock Audio")
        #expect(source.sourceType == .microphone)
        #expect(source.availability == .available)

        try await source.configure(.default)
        let configCount = await source.configureCallCount
        #expect(configCount == 1)

        let stream = try await source.startCapture()
        _ = stream
        let startCount = await source.startCaptureCallCount
        #expect(startCount == 1)

        let isCapturing = await source.isCapturing
        #expect(isCapturing == true)

        await source.stopCapture()
        let stopCount = await source.stopCaptureCallCount
        #expect(stopCount == 1)

        let isStopped = await source.isCapturing
        #expect(isStopped == false)
    }

    @Test("AudioSourceType CaseIterable count is eight")
    func audioSourceTypeCaseCount() {
        #expect(AudioSourceType.allCases.count == 8)
    }

    @Test("AudioSourceConfiguration default preset values")
    func defaultConfiguration() {
        let config = AudioSourceConfiguration.default
        #expect(config.sampleRate == .rate48000)
        #expect(config.channelCount == 2)
        #expect(config.channelLayout == .stereo)
        #expect(config.bitDepth == .float32)
        #expect(config.preferredBufferDuration == 0.02)
    }

    @Test("AudioLevelSample init stores properties")
    func audioLevelSampleInit() {
        let channels = [
            ChannelLevel(channel: 0, peak: -6.0, rms: -12.0),
            ChannelLevel(channel: 1, peak: -8.0, rms: -14.0)
        ]
        let sample = AudioLevelSample(
            timestamp: 1.0,
            peakLevel: -6.0,
            rmsLevel: -12.0,
            channels: channels,
            momentaryLoudness: -14.0,
            shortTermLoudness: -16.0,
            integratedLoudness: -18.0,
            truePeak: -5.5,
            loudnessRange: 8.0
        )
        #expect(sample.timestamp == 1.0)
        #expect(sample.peakLevel == -6.0)
        #expect(sample.rmsLevel == -12.0)
        #expect(sample.channels.count == 2)
        #expect(sample.momentaryLoudness == -14.0)
        #expect(sample.shortTermLoudness == -16.0)
        #expect(sample.integratedLoudness == -18.0)
        #expect(sample.truePeak == -5.5)
        #expect(sample.loudnessRange == 8.0)
    }

    @Test("ChannelLevel init and Equatable")
    func channelLevelInitAndEquatable() {
        let a = ChannelLevel(channel: 0, peak: -6.0, rms: -12.0)
        let b = ChannelLevel(channel: 0, peak: -6.0, rms: -12.0)
        let c = ChannelLevel(channel: 1, peak: -6.0, rms: -12.0)
        #expect(a == b)
        #expect(a != c)
        #expect(a.channel == 0)
        #expect(a.peak == -6.0)
        #expect(a.rms == -12.0)
    }
}
