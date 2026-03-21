// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("ChannelLayout", .timeLimit(.minutes(1)))
struct ChannelLayoutTests {

    @Test("CaseIterable count is 13")
    func caseIterableCount() {
        #expect(ChannelLayout.allCases.count == 13)
    }

    @Test("channelCount returns 1 for mono")
    func channelCountMono() {
        #expect(ChannelLayout.mono.channelCount == 1)
    }

    @Test("channelCount returns 2 for stereo")
    func channelCountStereo() {
        #expect(ChannelLayout.stereo.channelCount == 2)
    }

    @Test("channelCount returns 3 for stereoWithLFE")
    func channelCountStereoWithLFE() {
        #expect(ChannelLayout.stereoWithLFE.channelCount == 3)
    }

    @Test("channelCount returns 4 for quadraphonic")
    func channelCountQuadraphonic() {
        #expect(ChannelLayout.quadraphonic.channelCount == 4)
    }

    @Test("channelCount returns 5 for surround50")
    func channelCountSurround50() {
        #expect(ChannelLayout.surround50.channelCount == 5)
    }

    @Test("channelCount returns 6 for surround51")
    func channelCountSurround51() {
        #expect(ChannelLayout.surround51.channelCount == 6)
    }

    @Test("channelCount returns 7 for surround61")
    func channelCountSurround61() {
        #expect(ChannelLayout.surround61.channelCount == 7)
    }

    @Test("channelCount returns 8 for surround71")
    func channelCountSurround71() {
        #expect(ChannelLayout.surround71.channelCount == 8)
    }

    @Test("channelCount returns 12 for surround714")
    func channelCountSurround714() {
        #expect(ChannelLayout.surround714.channelCount == 12)
    }

    @Test("channelCount returns 4 for ambisonicFOA")
    func channelCountAmbisonicFOA() {
        #expect(ChannelLayout.ambisonicFOA.channelCount == 4)
    }

    @Test("channelCount returns 9 for ambisonicSOA")
    func channelCountAmbisonicSOA() {
        #expect(ChannelLayout.ambisonicSOA.channelCount == 9)
    }

    @Test("channelCount returns 16 for ambisonicTOA")
    func channelCountAmbisonicTOA() {
        #expect(ChannelLayout.ambisonicTOA.channelCount == 16)
    }

    @Test("channelCount returns 2 for binaural")
    func channelCountBinaural() {
        #expect(ChannelLayout.binaural.channelCount == 2)
    }
}
