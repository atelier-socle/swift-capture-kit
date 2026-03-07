// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ToneSource")
struct ToneSourceTests {

    private static let shortBufferConfig = AudioSourceConfiguration(
        sampleRate: .rate48000,
        channelCount: 1,
        channelLayout: .mono,
        bitDepth: .float32,
        preferredBufferDuration: 0.01
    )

    @Test("has generator source type")
    func hasGeneratorSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource()
        #expect(await source.sourceType == .generator)
    }

    @Test("default waveform is sine")
    func defaultWaveformIsSine() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource()
        #expect(await source.waveform == .sine)
    }

    @Test("default frequency is 440 Hz")
    func defaultFrequencyIs440() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource()
        #expect(await source.frequency == 440.0)
    }

    @Test("default amplitude is 0.5")
    func defaultAmplitudeIsHalf() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource()
        #expect(await source.amplitude == 0.5)
    }

    @Test("display name is Tone Generator")
    func displayNameIsToneGenerator() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource()
        #expect(await source.displayName == "Tone Generator")
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource()
        try await source.configure(Self.shortBufferConfig)
        let format = await source.activeFormat
        #expect(format != nil)
        #expect(format?.sampleRate == .rate48000)
    }

    @Test("startCapture produces non-silent buffers")
    func startCaptureProducesNonSilentBuffers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(format: Self.shortBufferConfig)
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let data = try #require(firstBuffer?.data)
        let hasNonZero = data.contains { $0 != 0 }
        #expect(hasNonZero)
    }

    @Test("sine waveform produces non-zero samples")
    func sineWaveformProducesNonZeroSamples() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(waveform: .sine, frequency: 1000.0, amplitude: 0.5, format: Self.shortBufferConfig)
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let data = try #require(firstBuffer?.data)
        let hasNonZeroSample = data.withUnsafeBytes { ptr in
            let floats = ptr.bindMemory(to: Float.self)
            return floats.contains { $0 != 0.0 }
        }
        #expect(hasNonZeroSample)
    }

    @Test("square waveform produces values near plus 1 or minus 1")
    func squareWaveformProducesExpectedValues() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(waveform: .square, frequency: 1000.0, amplitude: 1.0, format: Self.shortBufferConfig)
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let data = try #require(firstBuffer?.data)
        let allNearPlusOrMinusOne = data.withUnsafeBytes { ptr in
            let floats = ptr.bindMemory(to: Float.self)
            return floats.allSatisfy { abs(abs($0) - 1.0) < 0.01 }
        }
        #expect(allNearPlusOrMinusOne)
    }

    @Test("amplitude of zero produces silence")
    func amplitudeOfZeroProducesSilence() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(waveform: .sine, frequency: 440.0, amplitude: 0.0, format: Self.shortBufferConfig)
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let data = try #require(firstBuffer?.data)
        let allZero = data.withUnsafeBytes { ptr in
            let floats = ptr.bindMemory(to: Float.self)
            return floats.allSatisfy { $0 == 0.0 }
        }
        #expect(allZero)
    }

    @Test("buffer data size matches expected sample count")
    func bufferDataSizeMatchesExpected() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let config = AudioSourceConfiguration(
            sampleRate: .rate48000,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .float32,
            preferredBufferDuration: 0.01
        )
        let source = ToneSource(format: config)
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let data = try #require(firstBuffer?.data)
        let samplesPerBuffer = Int(config.sampleRate.rawValue * config.preferredBufferDuration)
        let expectedSize = samplesPerBuffer * config.channelCount * 4
        #expect(data.count == expectedSize)
    }

    @Test("all waveform types produce valid output")
    func allWaveformTypesProduceValidOutput() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        for waveform in ToneWaveform.allCases {
            let source = ToneSource(waveform: waveform, frequency: 440.0, amplitude: 0.5, format: Self.shortBufferConfig)
            let stream = try await source.startCapture()
            var gotBuffer = false
            for await _ in stream {
                gotBuffer = true
                break
            }
            await source.stopCapture()
            #expect(gotBuffer, "Waveform \(waveform.rawValue) did not produce a buffer")
        }
    }

    @Test("EBU R128 calibration tone produces low amplitude")
    func ebuR128CalibrationToneProducesLowAmplitude() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(waveform: .ebur128Calibration, frequency: 1000.0, amplitude: 1.0, format: Self.shortBufferConfig)
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let data = try #require(firstBuffer?.data)
        let maxSample = data.withUnsafeBytes { ptr in
            let floats = ptr.bindMemory(to: Float.self)
            return floats.max(by: { abs($0) < abs($1) }).map { abs($0) } ?? 0.0
        }
        #expect(maxSample < 0.15)
    }

    @Test("frequency can be set at init")
    func frequencyCanBeSet() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(frequency: 880.0)
        #expect(await source.frequency == 880.0)
    }

    @Test("waveform can be set at init")
    func waveformCanBeSet() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(waveform: .triangle)
        #expect(await source.waveform == .triangle)
    }

    @Test("supports stereo configuration")
    func supportsStereoConfiguration() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let config = AudioSourceConfiguration(
            sampleRate: .rate48000,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .float32,
            preferredBufferDuration: 0.01
        )
        let source = ToneSource()
        try await source.configure(config)
        let format = await source.activeFormat
        #expect(format?.channelCount == 2)
    }

    @Test("supports mono configuration")
    func supportsMonoConfiguration() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let config = AudioSourceConfiguration(
            sampleRate: .rate48000,
            channelCount: 1,
            channelLayout: .mono,
            bitDepth: .float32,
            preferredBufferDuration: 0.01
        )
        let source = ToneSource()
        try await source.configure(config)
        let format = await source.activeFormat
        #expect(format?.channelCount == 1)
    }

    @Test("noise waveforms produce varying samples")
    func noiseWaveformsProduceVaryingSamples() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(waveform: .whiteNoise, frequency: 440.0, amplitude: 1.0, format: Self.shortBufferConfig)
        let stream = try await source.startCapture()
        var firstBuffer: AudioBuffer?
        for await buffer in stream {
            firstBuffer = buffer
            break
        }
        await source.stopCapture()

        let data = try #require(firstBuffer?.data)
        let hasVariation = data.withUnsafeBytes { ptr in
            let floats = ptr.bindMemory(to: Float.self)
            guard let first = floats.first else { return false }
            return floats.contains { $0 != first }
        }
        #expect(hasVariation)
    }

    @Test("stopCapture transitions state correctly")
    func stopCaptureTransitionsState() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(format: Self.shortBufferConfig)
        _ = try await source.startCapture()
        #expect(await source.isCapturing == true)
        await source.stopCapture()
        #expect(await source.isCapturing == false)
    }

    @Test("sequential buffers have incrementing sequence numbers")
    func sequentialBuffersHaveIncrementingSequenceNumbers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ToneSource(format: Self.shortBufferConfig)
        let stream = try await source.startCapture()
        var buffers: [AudioBuffer] = []
        for await buffer in stream {
            buffers.append(buffer)
            if buffers.count >= 2 { break }
        }
        await source.stopCapture()

        #expect(buffers.count == 2)
        #expect(buffers[1].sequenceNumber > buffers[0].sequenceNumber)
    }
}
