// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("VideoResolution", .timeLimit(.minutes(1)))
struct VideoResolutionTests {

    @Test("width and height for all named cases")
    func widthAndHeightForNamedCases() {
        #expect(VideoResolution.qvga.width == 320)
        #expect(VideoResolution.qvga.height == 240)
        #expect(VideoResolution.vga.width == 640)
        #expect(VideoResolution.vga.height == 480)
        #expect(VideoResolution.p540.width == 960)
        #expect(VideoResolution.p540.height == 540)
        #expect(VideoResolution.p720.width == 1280)
        #expect(VideoResolution.p720.height == 720)
        #expect(VideoResolution.p1080.width == 1920)
        #expect(VideoResolution.p1080.height == 1080)
        #expect(VideoResolution.p1440.width == 2560)
        #expect(VideoResolution.p1440.height == 1440)
        #expect(VideoResolution.uhd4K.width == 3840)
        #expect(VideoResolution.uhd4K.height == 2160)
        #expect(VideoResolution.dci4K.width == 4096)
        #expect(VideoResolution.dci4K.height == 2160)
        #expect(VideoResolution.uhd8K.width == 7680)
        #expect(VideoResolution.uhd8K.height == 4320)
        #expect(VideoResolution.square720.width == 720)
        #expect(VideoResolution.square720.height == 720)
        #expect(VideoResolution.square1080.width == 1080)
        #expect(VideoResolution.square1080.height == 1080)
        #expect(VideoResolution.vertical720.width == 720)
        #expect(VideoResolution.vertical720.height == 1280)
        #expect(VideoResolution.vertical1080.width == 1080)
        #expect(VideoResolution.vertical1080.height == 1920)
        #expect(VideoResolution.spatialVideo.width == 1920)
        #expect(VideoResolution.spatialVideo.height == 1080)
    }

    @Test("custom resolution returns correct width and height")
    func customResolution() {
        let custom = VideoResolution.custom(width: 800, height: 600)
        #expect(custom.width == 800)
        #expect(custom.height == 600)
    }

    @Test("aspectRatio for p1080 equals 1920 divided by 1080")
    func aspectRatioP1080() {
        let expected = 1920.0 / 1080.0
        #expect(VideoResolution.p1080.aspectRatio == expected)
    }

    @Test("totalPixels for p1080 equals 1920 times 1080")
    func totalPixelsP1080() {
        #expect(VideoResolution.p1080.totalPixels == 1920 * 1080)
    }

    @Test("Equatable: p1080 equals p1080")
    func equatableSameCase() {
        #expect(VideoResolution.p1080 == VideoResolution.p1080)
    }

    @Test("Equatable: p1080 does not equal p720")
    func equatableDifferentCases() {
        #expect(VideoResolution.p1080 != VideoResolution.p720)
    }

    @Test("Equatable: custom with same values are equal")
    func equatableCustomSameValues() {
        let a = VideoResolution.custom(width: 1920, height: 1080)
        let b = VideoResolution.custom(width: 1920, height: 1080)
        #expect(a == b)
    }

    @Test("Equatable: custom with different values are not equal")
    func equatableCustomDifferentValues() {
        let a = VideoResolution.custom(width: 1920, height: 1080)
        let b = VideoResolution.custom(width: 1280, height: 720)
        #expect(a != b)
    }
}
