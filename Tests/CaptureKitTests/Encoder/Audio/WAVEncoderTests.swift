// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("WAVEncoder")
struct WAVEncoderTests {
    private func makeEncoder() -> WAVEncoder {
        WAVEncoder(configuration: .cdQuality)
    }

    private func makeBuffer(size: Int = 1024) -> AudioBuffer {
        let format = AudioFormat(
            sampleRate: .rate44100,
            channelCount: 2,
            bitDepth: .int16
        )
        return AudioBuffer(
            data: Data(repeating: 0, count: size),
            format: format,
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 1
        )
    }

    @Test("header is 44 bytes")
    func headerIs44Bytes() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(wav: .cdQuality)
        let header = await encoder.buildWAVHeader()
        #expect(header.count == 44)
    }

    @Test("RIFF magic bytes correct")
    func riffMagicBytesCorrect() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(wav: .cdQuality)
        let header = await encoder.buildWAVHeader()
        let riffBytes = Array(header[0..<4])
        #expect(riffBytes == [0x52, 0x49, 0x46, 0x46])
    }

    @Test("WAVE identifier correct")
    func waveIdentifierCorrect() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(wav: .cdQuality)
        let header = await encoder.buildWAVHeader()
        let waveBytes = Array(header[8..<12])
        #expect(waveBytes == [0x57, 0x41, 0x56, 0x45])
    }

    @Test("fmt chunk has correct PCM format")
    func fmtChunkHasCorrectPCMFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(wav: .cdQuality)
        let header = await encoder.buildWAVHeader()
        let audioFormat = UInt16(header[20]) | (UInt16(header[21]) << 8)
        #expect(audioFormat == 1)
    }

    @Test("encode produces header plus data on first call")
    func encodeProducesHeaderPlusDataOnFirstCall() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(wav: .cdQuality)
        let buffer = makeBuffer()
        let result = try await encoder.encode(buffer)
        #expect(result.data.count == 44 + buffer.data.count)
    }

    @Test("subsequent encodes produce data only")
    func subsequentEncodesProduceDataOnly() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(wav: .cdQuality)
        let buffer = makeBuffer()
        _ = try await encoder.encode(buffer)
        let secondResult = try await encoder.encode(buffer)
        #expect(secondResult.data.count == buffer.data.count)
    }

    @Test("flush returns updated header with final size")
    func flushReturnsUpdatedHeaderWithFinalSize() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(wav: .cdQuality)
        let buffer = makeBuffer(size: 512)
        _ = try await encoder.encode(buffer)
        let flushed = try await encoder.flush()
        #expect(flushed.count == 1)
        let finalHeader = flushed[0].data
        #expect(finalHeader.count == 44)
        let dataSize =
            UInt32(finalHeader[40])
            | (UInt32(finalHeader[41]) << 8)
            | (UInt32(finalHeader[42]) << 16)
            | (UInt32(finalHeader[43]) << 24)
        #expect(dataSize == 512)
    }

    @Test("reset clears state")
    func resetClearsState() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = makeEncoder()
        try await encoder.configure(wav: .cdQuality)
        #expect(await encoder.isConfigured == true)
        await encoder.reset()
        #expect(await encoder.isConfigured == false)
    }
}
