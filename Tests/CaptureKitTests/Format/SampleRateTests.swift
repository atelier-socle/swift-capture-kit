// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("SampleRate")
struct SampleRateTests {

    @Test("CaseIterable count is 13")
    func caseIterableCount() {
        #expect(SampleRate.allCases.count == 13)
    }

    @Test("rawValue correctness for every case")
    func rawValues() {
        #expect(SampleRate.rate8000.rawValue == 8000)
        #expect(SampleRate.rate11025.rawValue == 11025)
        #expect(SampleRate.rate16000.rawValue == 16000)
        #expect(SampleRate.rate22050.rawValue == 22050)
        #expect(SampleRate.rate32000.rawValue == 32000)
        #expect(SampleRate.rate44100.rawValue == 44100)
        #expect(SampleRate.rate48000.rawValue == 48000)
        #expect(SampleRate.rate88200.rawValue == 88200)
        #expect(SampleRate.rate96000.rawValue == 96000)
        #expect(SampleRate.rate176400.rawValue == 176400)
        #expect(SampleRate.rate192000.rawValue == 192000)
        #expect(SampleRate.rate352800.rawValue == 352800)
        #expect(SampleRate.rate384000.rawValue == 384000)
    }

    @Test("Comparable ordering: rate8000 < rate44100")
    func comparableOrdering8000LessThan44100() {
        #expect(SampleRate.rate8000 < SampleRate.rate44100)
    }

    @Test("Comparable ordering: rate44100 < rate384000")
    func comparableOrdering44100LessThan384000() {
        #expect(SampleRate.rate44100 < SampleRate.rate384000)
    }

    @Test("Comparable ordering: rate384000 is not less than rate8000")
    func comparableOrderingHighNotLessThanLow() {
        #expect(!(SampleRate.rate384000 < SampleRate.rate8000))
    }

    @Test("48000 Hz is the standard broadcast rate")
    func rate48000IsStandard() {
        #expect(SampleRate.rate48000.rawValue == 48000)
    }

    @Test("All cases are sorted ascending by rawValue")
    func allCasesSortedAscending() {
        let sorted = SampleRate.allCases.sorted()
        #expect(sorted == SampleRate.allCases)
    }
}
