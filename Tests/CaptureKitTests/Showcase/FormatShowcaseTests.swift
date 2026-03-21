// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Format Showcase", .tags(.showcase))
struct FormatShowcaseTests {

    // MARK: - SampleRate

    @Test("SampleRate raw values match expected frequencies")
    func sampleRateRawValues() {
        #expect(SampleRate.rate8000.rawValue == 8000)
        #expect(SampleRate.rate11025.rawValue == 11025)
        #expect(SampleRate.rate16000.rawValue == 16000)
        #expect(SampleRate.rate22050.rawValue == 22050)
        #expect(SampleRate.rate24000.rawValue == 24000)
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

    @Test("SampleRate is Comparable")
    func sampleRateComparison() {
        #expect(SampleRate.rate8000 < SampleRate.rate48000)
        #expect(SampleRate.rate48000 < SampleRate.rate96000)
        #expect(SampleRate.rate96000 < SampleRate.rate384000)
    }

    @Test("SampleRate CaseIterable enumerates all rates")
    func sampleRateAllCases() {
        #expect(SampleRate.allCases.count == 14)
    }

    // MARK: - ChannelLayout

    @Test("ChannelLayout channel counts match expected values")
    func channelLayoutCounts() {
        #expect(ChannelLayout.mono.channelCount == 1)
        #expect(ChannelLayout.stereo.channelCount == 2)
        #expect(ChannelLayout.stereoWithLFE.channelCount == 3)
        #expect(ChannelLayout.quadraphonic.channelCount == 4)
        #expect(ChannelLayout.surround50.channelCount == 5)
        #expect(ChannelLayout.surround51.channelCount == 6)
        #expect(ChannelLayout.surround61.channelCount == 7)
        #expect(ChannelLayout.surround71.channelCount == 8)
        #expect(ChannelLayout.surround714.channelCount == 12)
        #expect(ChannelLayout.binaural.channelCount == 2)
    }

    @Test("ChannelLayout ambisonic orders")
    func channelLayoutAmbisonics() {
        #expect(ChannelLayout.ambisonicFOA.channelCount == 4)
        #expect(ChannelLayout.ambisonicSOA.channelCount == 9)
        #expect(ChannelLayout.ambisonicTOA.channelCount == 16)
    }

    @Test("ChannelLayout CaseIterable enumerates all layouts")
    func channelLayoutAllCases() {
        #expect(ChannelLayout.allCases.count == 13)
    }

    // MARK: - VideoResolution

    @Test("VideoResolution standard dimensions")
    func videoResolutionDimensions() {
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
    }

    @Test("VideoResolution social media dimensions")
    func videoResolutionSocial() {
        #expect(VideoResolution.square720.width == 720)
        #expect(VideoResolution.square720.height == 720)
        #expect(VideoResolution.square1080.width == 1080)
        #expect(VideoResolution.square1080.height == 1080)
        #expect(VideoResolution.vertical720.width == 720)
        #expect(VideoResolution.vertical720.height == 1280)
        #expect(VideoResolution.vertical1080.width == 1080)
        #expect(VideoResolution.vertical1080.height == 1920)
    }

    @Test("VideoResolution custom dimensions")
    func videoResolutionCustom() {
        let custom = VideoResolution.custom(width: 1600, height: 900)
        #expect(custom.width == 1600)
        #expect(custom.height == 900)
    }

    @Test("VideoResolution spatialVideo dimensions")
    func videoResolutionSpatial() {
        #expect(VideoResolution.spatialVideo.width == 1920)
        #expect(VideoResolution.spatialVideo.height == 1080)
    }

    // MARK: - AudioBitDepth

    @Test("AudioBitDepth enumerates all bit depths")
    func audioBitDepthCases() {
        let depths = AudioBitDepth.allCases
        #expect(depths.contains(.int16))
        #expect(depths.contains(.int24))
        #expect(depths.contains(.int32))
        #expect(depths.contains(.float32))
        #expect(depths.contains(.float64))
    }

    // MARK: - BitDepth (Video)

    @Test("BitDepth raw values match bit counts")
    func bitDepthRawValues() {
        #expect(BitDepth.bit8.rawValue == 8)
        #expect(BitDepth.bit10.rawValue == 10)
        #expect(BitDepth.bit12.rawValue == 12)
        #expect(BitDepth.bit16.rawValue == 16)
    }

    @Test("BitDepth is Comparable")
    func bitDepthComparison() {
        #expect(BitDepth.bit8 < BitDepth.bit10)
        #expect(BitDepth.bit10 < BitDepth.bit12)
        #expect(BitDepth.bit12 < BitDepth.bit16)
    }

    // MARK: - PixelFormat

    @Test("PixelFormat enumerates all formats")
    func pixelFormatCases() {
        let formats = PixelFormat.allCases
        #expect(formats.contains(.nv12))
        #expect(formats.contains(.bgra))
        #expect(formats.contains(.p210))
        #expect(formats.contains(.p010))
        #expect(formats.contains(.argb))
        #expect(formats.contains(.yuvs))
    }

    // MARK: - ColorSpace

    @Test("ColorSpace enumerates all spaces")
    func colorSpaceCases() {
        let spaces = ColorSpace.allCases
        #expect(spaces.contains(.srgb))
        #expect(spaces.contains(.displayP3))
        #expect(spaces.contains(.bt709))
        #expect(spaces.contains(.bt2020))
        #expect(spaces.contains(.bt2100PQ))
        #expect(spaces.contains(.bt2100HLG))
        #expect(spaces.contains(.dcip3))
        #expect(spaces.contains(.adobeRGB))
    }

    // MARK: - DynamicRange

    @Test("DynamicRange enumerates all ranges")
    func dynamicRangeCases() {
        let ranges = DynamicRange.allCases
        #expect(ranges.contains(.sdr))
        #expect(ranges.contains(.hdr10))
        #expect(ranges.contains(.hdr10Plus))
        #expect(ranges.contains(.dolbyVision))
        #expect(ranges.contains(.hlg))
    }

    // MARK: - VideoStabilization

    @Test("VideoStabilization enumerates all modes")
    func videoStabilizationCases() {
        let modes = VideoStabilization.allCases
        #expect(modes.contains(.off))
        #expect(modes.contains(.standard))
        #expect(modes.contains(.cinematic))
        #expect(modes.contains(.cinematicExtended))
        #expect(modes.contains(.auto))
        #expect(modes.contains(.preferCinematic))
    }

    // MARK: - AudioFormat

    @Test("AudioFormat stores all fields correctly")
    func audioFormatFields() {
        let format = AudioFormat(
            sampleRate: .rate96000,
            channelCount: 2,
            channelLayout: .stereo,
            bitDepth: .int24
        )
        #expect(format.sampleRate == .rate96000)
        #expect(format.channelCount == 2)
        #expect(format.channelLayout == .stereo)
        #expect(format.bitDepth == .int24)
    }

    // MARK: - VideoFormat

    @Test("VideoFormat stores all fields correctly")
    func videoFormatFields() {
        let format = VideoFormat(
            resolution: .uhd4K,
            frameRate: .fps60,
            pixelFormat: .p010,
            colorSpace: .bt2020,
            dynamicRange: .hdr10
        )
        #expect(format.resolution == .uhd4K)
        #expect(format.frameRate == .fps60)
        #expect(format.pixelFormat == .p010)
        #expect(format.colorSpace == .bt2020)
        #expect(format.dynamicRange == .hdr10)
    }

    // MARK: - FrameRate

    @Test("FrameRate values match expected fps")
    func frameRateValues() {
        #expect(FrameRate.fps24.value == 24.0)
        #expect(FrameRate.fps30.value == 30.0)
        #expect(FrameRate.fps60.value == 60.0)
        #expect(FrameRate.fps120.value == 120.0)
        #expect(FrameRate.fps240.value == 240.0)
    }

    // MARK: - ProResProfile

    @Test("ProResProfile enumerates all profiles")
    func proResProfileCases() {
        let profiles = ProResProfile.allCases
        #expect(profiles.contains(.proxy))
        #expect(profiles.contains(.lt))
        #expect(profiles.contains(.standard))
        #expect(profiles.contains(.hq))
        #expect(profiles.contains(.p4444))
    }
}
