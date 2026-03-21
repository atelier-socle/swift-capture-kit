// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Audio Capture Showcase", .tags(.showcase))
struct AudioCaptureShowcaseTests {

    // MARK: - ToneSource

    @Test("Create and configure a tone generator source")
    func configureToneSource() async throws {
        let tone = ToneSource(
            waveform: .sine,
            frequency: 440.0,
            amplitude: 0.5
        )
        try await tone.configure(.default)
        let format = await tone.activeFormat
        #expect(format != nil)
        #expect(format?.sampleRate == .rate48000)
    }

    @Test("ToneSource supports all waveform types")
    func allWaveforms() async throws {
        for waveform in ToneWaveform.allCases {
            let tone = ToneSource(waveform: waveform)
            try await tone.configure(.default)
            let stream = try await tone.startCapture()
            var receivedBuffer = false
            for await buffer in stream {
                #expect(buffer.data.count > 0)
                #expect(buffer.duration > 0)
                receivedBuffer = true
                break
            }
            await tone.stopCapture()
            #expect(receivedBuffer, "Waveform \(waveform) produced no buffers")
        }
    }

    @Test("ToneSource generates audio at configured sample rate")
    func toneSourceSampleRate() async throws {
        let tone = ToneSource(frequency: 1000.0)
        let config = AudioSourceConfiguration(
            sampleRate: .rate48000,
            channelCount: 1,
            channelLayout: .mono,
            bitDepth: .float32,
            preferredBufferDuration: 0.02
        )
        try await tone.configure(config)
        let format = await tone.activeFormat
        #expect(format?.sampleRate == .rate48000)
        #expect(format?.channelCount == 1)
    }

    @Test("Start and stop audio capture lifecycle")
    func startStopCapture() async throws {
        let tone = ToneSource()
        try await tone.configure(.default)
        #expect(await tone.isCapturing == false)

        let stream = try await tone.startCapture()
        #expect(await tone.isCapturing == true)

        for await _ in stream { break }

        await tone.stopCapture()
        #expect(await tone.isCapturing == false)
    }

    // MARK: - MockAudioSource

    @Test("Configure mock audio source with custom settings")
    func configureMockSource() async throws {
        let source = MockAudioSource(
            sourceID: "test-mic",
            displayName: "Test Microphone",
            sourceType: .microphone
        )
        let config = AudioSourceConfiguration.voiceChat
        try await source.configure(config)
        let format = await source.activeFormat
        #expect(format?.sampleRate == .rate16000)
        #expect(format?.channelCount == 1)
        #expect(await source.configureCallCount == 1)
    }

    // MARK: - Audio Formats

    @Test("SampleRate raw values match expected frequencies")
    func sampleRateValues() {
        #expect(SampleRate.rate8000.rawValue == 8000)
        #expect(SampleRate.rate16000.rawValue == 16000)
        #expect(SampleRate.rate44100.rawValue == 44100)
        #expect(SampleRate.rate48000.rawValue == 48000)
        #expect(SampleRate.rate96000.rawValue == 96000)
    }

    @Test("ChannelLayout provides correct channel counts")
    func channelLayoutCounts() {
        #expect(ChannelLayout.mono.channelCount == 1)
        #expect(ChannelLayout.stereo.channelCount == 2)
        #expect(ChannelLayout.surround51.channelCount == 6)
        #expect(ChannelLayout.surround71.channelCount == 8)
    }

    @Test("AudioSourceConfiguration presets are valid")
    func audioConfigPresets() {
        let defaults = AudioSourceConfiguration.default
        #expect(defaults.sampleRate == .rate48000)
        #expect(defaults.channelCount == 2)
        #expect(defaults.bitDepth == .float32)

        let voice = AudioSourceConfiguration.voiceChat
        #expect(voice.sampleRate == .rate16000)
        #expect(voice.channelCount == 1)

        let broadcast = AudioSourceConfiguration.broadcast
        #expect(broadcast.preferredBufferDuration == 0.01)

        let hiRes = AudioSourceConfiguration.highResolution
        #expect(hiRes.sampleRate == .rate96000)
    }

    // MARK: - AudioBuffer

    @Test("Create AudioBuffer with correct properties")
    func createAudioBuffer() {
        let data = Data(repeating: 0, count: 3840)
        let format = AudioFormat(
            sampleRate: .rate48000,
            channelCount: 1,
            channelLayout: .mono,
            bitDepth: .float32
        )
        let buffer = CaptureKit.AudioBuffer(
            data: data,
            format: format,
            timestamp: 1.5,
            duration: 0.02,
            sequenceNumber: 42
        )
        #expect(buffer.data.count == 3840)
        #expect(buffer.timestamp == 1.5)
        #expect(buffer.duration == 0.02)
        #expect(buffer.sequenceNumber == 42)
        #expect(buffer.format.sampleRate == .rate48000)
    }
}
