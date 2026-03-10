// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PassthroughAudioEncoder")
struct PassthroughAudioEncoderTests {

    @Test("configure does not throw")
    func configureDoesNotThrow() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughAudioEncoder()
        try await encoder.configure(
            inputFormat: AudioFormat(sampleRate: .rate48000, channelCount: 2),
            outputCodec: .aac,
            bitrate: 128_000,
            sampleRate: .rate48000,
            channelCount: 2
        )
    }

    @Test("encode returns data unchanged from input")
    func encodeReturnsDataUnchanged() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughAudioEncoder()
        let inputData = Data([0x01, 0x02, 0x03, 0x04])
        let (result, _) = try await encoder.encode(data: inputData, timestamp: 1.0)
        #expect(result == inputData)
    }

    @Test("flush returns nil")
    func flushReturnsNil() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughAudioEncoder()
        let result = try await encoder.flush()
        #expect(result == nil)
    }

    @Test("reset does not throw")
    func resetDoesNotThrow() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughAudioEncoder()
        await encoder.reset()
    }

    @Test("multiple sequential encodes return correct data each time")
    func multipleEncodesWork() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughAudioEncoder()
        let first = Data([0xAA, 0xBB])
        let second = Data([0xCC, 0xDD, 0xEE])
        let third = Data([0xFF])

        let (result1, _) = try await encoder.encode(data: first, timestamp: 0.0)
        let (result2, _) = try await encoder.encode(data: second, timestamp: 0.5)
        let (result3, _) = try await encoder.encode(data: third, timestamp: 1.0)

        #expect(result1 == first)
        #expect(result2 == second)
        #expect(result3 == third)
    }

    @Test("encode preserves exact byte content and length")
    func encodePreservesFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughAudioEncoder()
        let sampleBytes: [UInt8] = Array(0..<255)
        let inputData = Data(sampleBytes)
        let (result, packetSizes) = try await encoder.encode(data: inputData, timestamp: 2.5)
        #expect(result.count == inputData.count)
        #expect(result == inputData)
        #expect(packetSizes == nil)
    }

    @Test("flush returns nil even after encoding")
    func flushAfterEncodeReturnsNil() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let encoder = PassthroughAudioEncoder()
        _ = try await encoder.encode(data: Data([0x01]), timestamp: 0.0)
        let result = try await encoder.flush()
        #expect(result == nil)
    }
}
