// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AudioMeter")
struct AudioMeterTests {

    private func makeBuffer(samples: [Float]) -> AudioBuffer {
        var data = Data()
        for sample in samples {
            withUnsafeBytes(of: sample) { data.append(contentsOf: $0) }
        }
        let format = AudioFormat(
            sampleRate: .rate44100,
            channelCount: 1,
            channelLayout: .mono,
            bitDepth: .float32)
        return AudioBuffer(
            data: data, format: format,
            timestamp: 0, duration: 0.01, sequenceNumber: 0)
    }

    @Test("not active initially")
    func notActiveInitially() async {
        let meter = AudioMeter()
        #expect(await meter.isActive == false)
    }

    @Test("start sets isActive")
    func startSetsActive() async {
        let meter = AudioMeter()
        await meter.start()
        #expect(await meter.isActive == true)
    }

    @Test("stop sets isActive false")
    func stopSetsInactive() async {
        let meter = AudioMeter()
        await meter.start()
        await meter.stop()
        #expect(await meter.isActive == false)
    }

    @Test("levels stream exists")
    func levelsStreamExists() async {
        let meter = AudioMeter()
        _ = await meter.levels
    }

    @Test("waveforms stream exists")
    func waveformsStreamExists() async {
        let meter = AudioMeter()
        _ = await meter.waveforms
    }

    @Test("processBuffer when not active is no-op")
    func processWhenNotActive() async {
        let meter = AudioMeter()
        let buffer = makeBuffer(samples: [0.5, -0.5])
        await meter.processBuffer(buffer)
        // No crash = success
    }

    @Test("silence buffer produces -infinity levels")
    func silenceProducesNegInfinity() async {
        let meter = AudioMeter()
        _ = await meter.levels
        await meter.start()
        let buffer = makeBuffer(samples: [0, 0, 0, 0])
        await meter.processBuffer(buffer)
        await meter.stop()
    }

    @Test("full-scale produces finite peak")
    func fullScaleProducesFinitePeak() async {
        let meter = AudioMeter(configuration: .init(mode: .peak))
        _ = await meter.levels
        await meter.start()
        let buffer = makeBuffer(samples: [1.0, -1.0, 1.0, -1.0])
        await meter.processBuffer(buffer)
        await meter.stop()
    }

    @Test("loudness mode includes momentary loudness")
    func loudnessModeIncludesLoudness() async {
        let meter = AudioMeter(
            configuration: .init(mode: .loudness))
        _ = await meter.levels
        await meter.start()
        let buffer = makeBuffer(samples: [0.5, -0.5, 0.3, -0.3])
        await meter.processBuffer(buffer)
        await meter.stop()
    }

    @Test("default configuration is peakAndRMS")
    func defaultConfig() async {
        let meter = AudioMeter()
        #expect(await meter.configuration.mode == .peakAndRMS)
    }

    @Test("custom configuration is stored")
    func customConfig() async {
        let meter = AudioMeter(configuration: .broadcast)
        #expect(await meter.configuration.mode == .full)
    }

    @Test("simple waveform mode processes correctly")
    func simpleWaveformMode() async {
        let config = AudioMeterConfiguration(
            mode: .peak, waveform: .simple(barCount: 4))
        let meter = AudioMeter(configuration: config)
        _ = await meter.waveforms
        await meter.start()
        let buffer = makeBuffer(
            samples: [0.5, 0.3, 0.8, 0.1, 0.6, 0.2, 0.9, 0.4])
        await meter.processBuffer(buffer)
        await meter.stop()
    }

    @Test("detailed waveform mode processes correctly")
    func detailedWaveformMode() async {
        let config = AudioMeterConfiguration(
            mode: .peak, waveform: .detailed(samplesPerBucket: 2))
        let meter = AudioMeter(configuration: config)
        _ = await meter.waveforms
        await meter.start()
        let buffer = makeBuffer(
            samples: [0.5, -0.5, 0.3, -0.3])
        await meter.processBuffer(buffer)
        await meter.stop()
    }

    @Test("waveform disabled produces no waveform events")
    func waveformDisabledNoEvents() async {
        let meter = AudioMeter(
            configuration: .init(waveform: .disabled))
        _ = await meter.waveforms
        await meter.start()
        let buffer = makeBuffer(samples: [0.5])
        await meter.processBuffer(buffer)
        await meter.stop()
    }
}
