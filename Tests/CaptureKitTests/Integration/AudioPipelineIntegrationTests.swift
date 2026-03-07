// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Audio Pipeline Integration")
struct AudioPipelineIntegrationTests {

    private func makeBuffer(
        seq: Int64 = 0
    ) -> AudioBuffer {
        AudioBuffer(
            data: Data(repeating: 0x33, count: 512),
            format: AudioFormat(
                sampleRate: .rate48000,
                channelCount: 2,
                channelLayout: .stereo,
                bitDepth: .float32
            ),
            timestamp: Double(seq) * 0.02,
            duration: 0.02,
            sequenceNumber: seq
        )
    }

    @Test("mock engine to mock encoder pipeline")
    func mockEnginePipeline() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        await engine.setSyntheticSamples([
            CapturedAudioSample(
                data: Data(repeating: 0xAA, count: 256),
                timestamp: 0.0,
                format: AudioFormat(
                    sampleRate: .rate48000,
                    channelCount: 2,
                    channelLayout: .stereo,
                    bitDepth: .float32
                )
            )
        ])

        let source = MicrophoneSource(captureEngine: engine)
        let stream = try await source.startCapture()

        let encoderProvider = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast,
            encoderProvider: encoderProvider
        )
        try await encoder.configure(aac: .podcast)

        for await buffer in stream {
            let encoded = try await encoder.encode(buffer)
            #expect(encoded.codec == .aac)
            #expect(encoded.data.count == 256)
        }

        await source.stopCapture()
    }

    @Test("file source to encoder pipeline")
    func fileSourcePipeline() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let path =
            "/tmp/swift-capture-kit-pipeline-\(UUID().uuidString).wav"
        FileManager.default.createFile(
            atPath: path, contents: Data(count: 64))
        defer { try? FileManager.default.removeItem(atPath: path) }

        let reader = MockAudioFileReader()
        await reader.setSyntheticSamples([
            CapturedAudioSample(
                data: Data(repeating: 0xBB, count: 128),
                timestamp: 0.0,
                format: AudioFormat(
                    sampleRate: .rate48000,
                    channelCount: 1,
                    channelLayout: .mono,
                    bitDepth: .float32
                )
            )
        ])

        let source = FileAudioSource(
            url: URL(fileURLWithPath: path),
            fileReader: reader
        )
        let stream = try await source.startCapture()

        var count = 0
        for await buffer in stream {
            #expect(buffer.data.count == 128)
            count += 1
        }
        #expect(count == 1)
        await source.stopCapture()
    }

    @Test("encoder preserves sequence numbers")
    func encoderPreservesSequenceNumbers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        try await encoder.configure(aac: .podcast)

        var sequences: [Int64] = []
        for i in 0..<5 {
            let result = try await encoder.encode(
                makeBuffer(seq: Int64(i)))
            sequences.append(result.sequenceNumber)
        }
        #expect(sequences == [0, 1, 2, 3, 4])
    }

    @Test("encoder preserves timestamps")
    func encoderPreservesTimestamps() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        try await encoder.configure(aac: .podcast)

        let buffer = makeBuffer(seq: 3)
        let result = try await encoder.encode(buffer)
        #expect(result.timestamp == buffer.timestamp)
        #expect(result.duration == buffer.duration)
    }

    @Test("multiple encoder types work with same mock provider")
    func multipleEncoderTypes() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let buffer = makeBuffer()

        let aacMock = MockAudioEncoderProvider()
        let aac = AACEncoder(
            configuration: .podcast, encoderProvider: aacMock)
        try await aac.configure(aac: .podcast)
        let aacResult = try await aac.encode(buffer)
        #expect(aacResult.codec == .aac)

        let opusMock = MockAudioEncoderProvider()
        let opus = OpusEncoder(
            configuration: .musicStreaming,
            encoderProvider: opusMock
        )
        try await opus.configure(opus: .musicStreaming)
        let opusResult = try await opus.encode(buffer)
        #expect(opusResult.codec == .opus)

        let pcm = PCMEncoder()
        try await pcm.configure(pcm: .broadcast)
        let pcmResult = try await pcm.encode(buffer)
        #expect(pcmResult.codec == .pcm)
    }

    @Test("encoder reset then encode throws")
    func resetThenEncodeThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let mock = MockAudioEncoderProvider()
        let encoder = AACEncoder(
            configuration: .podcast, encoderProvider: mock)
        try await encoder.configure(aac: .podcast)
        await encoder.reset()

        await #expect(throws: CaptureError.self) {
            _ = try await encoder.encode(makeBuffer())
        }
    }

    @Test("system audio source with mock produces buffers")
    func systemAudioMockProducesBuffers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let provider = MockScreenCaptureAudioProvider()
        await provider.setSyntheticSamples([
            CapturedAudioSample(
                data: Data(repeating: 0xCC, count: 64),
                timestamp: 0.0,
                format: AudioFormat(
                    sampleRate: .rate48000,
                    channelCount: 2,
                    channelLayout: .stereo,
                    bitDepth: .float32
                )
            )
        ])

        let source = SystemAudioSource(
            audioProvider: provider)
        let stream = try await source.startCapture()

        var count = 0
        for await buffer in stream {
            #expect(buffer.data.count == 64)
            count += 1
        }
        #expect(count == 1)
        await source.stopCapture()
    }

    @Test("bluetooth source with mock engine")
    func bluetoothSourceWithMock() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        await engine.setSyntheticSamples([
            CapturedAudioSample(
                data: Data(repeating: 0xDD, count: 64),
                timestamp: 0.0,
                format: AudioFormat(
                    sampleRate: .rate48000,
                    channelCount: 1,
                    channelLayout: .mono,
                    bitDepth: .float32
                )
            )
        ])

        let device = AudioDeviceInfo(
            id: "bt-device",
            name: "BT Headset",
            manufacturer: "Test",
            connectionType: .bluetooth,
            inputChannelCount: 1,
            supportedSampleRates: [.rate48000]
        )
        let source = BluetoothAudioSource(
            device: device, captureEngine: engine)
        let stream = try await source.startCapture()

        var count = 0
        for await _ in stream {
            count += 1
        }
        #expect(count == 1)
        await source.stopCapture()
    }

    @Test("VoIP source configures audio session")
    func voipConfiguresSession() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
        else { return }

        let engine = MockAudioCaptureEngine()
        let source = VoIPAudioSource(captureEngine: engine)
        _ = try await source.startCapture()

        let category = await engine.lastSessionCategory
        let mode = await engine.lastSessionMode
        #expect(category == "playAndRecord")
        #expect(mode == "voiceChat")
        await source.stopCapture()
    }
}
