// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("VideoFormat", .timeLimit(.minutes(1)))
struct VideoFormatTests {

    @Test("Init with all parameters stores values correctly")
    func initWithAllParams() {
        let format = VideoFormat(
            resolution: .uhd4K,
            frameRate: .fps60,
            pixelFormat: .p010,
            colorSpace: .bt2020,
            dynamicRange: .hdr10,
            bitDepth: .bit10
        )
        #expect(format.resolution == .uhd4K)
        #expect(format.frameRate == .fps60)
        #expect(format.pixelFormat == .p010)
        #expect(format.colorSpace == .bt2020)
        #expect(format.dynamicRange == .hdr10)
        #expect(format.bitDepth == .bit10)
    }

    @Test("Init with defaults uses nv12, bt709, sdr, bit8")
    func initWithDefaults() {
        let format = VideoFormat(
            resolution: .p1080,
            frameRate: .fps30
        )
        #expect(format.pixelFormat == .nv12)
        #expect(format.colorSpace == .bt709)
        #expect(format.dynamicRange == .sdr)
        #expect(format.bitDepth == .bit8)
    }

    @Test("Equatable: identical formats are equal")
    func equatableIdentical() {
        let a = VideoFormat(resolution: .p1080, frameRate: .fps30)
        let b = VideoFormat(resolution: .p1080, frameRate: .fps30)
        #expect(a == b)
    }

    @Test("Equatable: different formats are not equal")
    func equatableDifferent() {
        let a = VideoFormat(resolution: .p1080, frameRate: .fps30)
        let b = VideoFormat(resolution: .p720, frameRate: .fps30)
        #expect(a != b)
    }

    @Test("Hashable: same values produce same hash")
    func hashableSameValues() {
        let a = VideoFormat(
            resolution: .p1080,
            frameRate: .fps24,
            pixelFormat: .bgra,
            colorSpace: .displayP3,
            dynamicRange: .dolbyVision,
            bitDepth: .bit12
        )
        let b = VideoFormat(
            resolution: .p1080,
            frameRate: .fps24,
            pixelFormat: .bgra,
            colorSpace: .displayP3,
            dynamicRange: .dolbyVision,
            bitDepth: .bit12
        )
        #expect(a.hashValue == b.hashValue)
    }

    @Test("Hashable: can be used as Set element")
    func hashableSetUsage() {
        let format = VideoFormat(resolution: .p1080, frameRate: .fps30)
        var set: Set<VideoFormat> = []
        set.insert(format)
        set.insert(format)
        #expect(set.count == 1)
    }
}
