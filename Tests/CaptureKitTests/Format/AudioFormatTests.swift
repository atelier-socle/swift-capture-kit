// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("AudioFormat", .timeLimit(.minutes(1)))
struct AudioFormatTests {

    @Test("Init with all parameters stores values correctly")
    func initWithAllParams() {
        let format = AudioFormat(
            sampleRate: .rate48000,
            channelCount: 6,
            channelLayout: .surround51,
            bitDepth: .int24,
            isInterleaved: false
        )
        #expect(format.sampleRate == .rate48000)
        #expect(format.channelCount == 6)
        #expect(format.channelLayout == .surround51)
        #expect(format.bitDepth == .int24)
        #expect(format.isInterleaved == false)
    }

    @Test("Init with defaults uses float32 and interleaved true")
    func initWithDefaults() {
        let format = AudioFormat(
            sampleRate: .rate44100,
            channelCount: 2
        )
        #expect(format.bitDepth == .float32)
        #expect(format.isInterleaved == true)
        #expect(format.channelLayout == nil)
    }

    @Test("Equatable: identical formats are equal")
    func equatableIdentical() {
        let a = AudioFormat(sampleRate: .rate48000, channelCount: 2, channelLayout: .stereo)
        let b = AudioFormat(sampleRate: .rate48000, channelCount: 2, channelLayout: .stereo)
        #expect(a == b)
    }

    @Test("Equatable: different formats are not equal")
    func equatableDifferent() {
        let a = AudioFormat(sampleRate: .rate48000, channelCount: 2)
        let b = AudioFormat(sampleRate: .rate44100, channelCount: 2)
        #expect(a != b)
    }

    @Test("Hashable: same values produce same hash")
    func hashableSameValues() {
        let a = AudioFormat(
            sampleRate: .rate48000,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .float32,
            isInterleaved: true
        )
        let b = AudioFormat(
            sampleRate: .rate48000,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .float32,
            isInterleaved: true
        )
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Hashable: can be used as Set element")
    func hashableSetUsage() {
        let format = AudioFormat(sampleRate: .rate48000, channelCount: 2)
        var set: Set<AudioFormat> = []
        set.insert(format)
        set.insert(format)
        #expect(set.count == 1)
    }
}
