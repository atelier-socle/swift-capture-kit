// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("TestPatternSource")
struct TestPatternSourceTests {

    @Test("has generator source type")
    func hasGeneratorSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource()
        #expect(await source.sourceType == .generator)
    }

    @Test("default pattern is smpteBars")
    func defaultPatternIsSmpteBars() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource()
        #expect(await source.pattern == .smpteBars)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource()
        let config = VideoSourceConfiguration(
            resolution: .p720,
            frameRate: .fps30,
            pixelFormat: .bgra,
            colorSpace: .bt709,
            dynamicRange: .sdr,
            stabilization: .off,
            focusMode: .locked,
            exposureMode: .locked,
            whiteBalanceMode: .locked
        )
        try await source.configure(config)
        let format = await source.activeFormat
        #expect(format != nil)
        #expect(format?.resolution == .p720)
    }

    @Test("SMPTE bars produce non-uniform frame data")
    func smpteBarsProduceNonUniformFrameData() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        // Use an 8-pixel wide, 1-pixel tall frame to check bar variation
        let data = TestPatternSource.generatePattern(.smpteBars, width: 8, height: 1)
        // First pixel and last pixel should differ (different bars)
        let firstB = data[0]
        let firstG = data[1]
        let firstR = data[2]
        let lastOffset = 7 * 4
        let lastB = data[lastOffset]
        let lastG = data[lastOffset + 1]
        let lastR = data[lastOffset + 2]
        let isDifferent = (firstB != lastB) || (firstG != lastG) || (firstR != lastR)
        #expect(isDifferent)
    }

    @Test("checkerboard produces alternating pixels")
    func checkerboardProducesAlternatingPixels() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        // Checkerboard uses 32-pixel squares, so use 64x1 to see alternation
        let data = TestPatternSource.generatePattern(.checkerboard, width: 64, height: 1)
        // Pixel at x=0 should be white (square 0, even), pixel at x=32 should be black (square 1, odd)
        let pixel0B = data[0]
        let pixel32Offset = 32 * 4
        let pixel32B = data[pixel32Offset]
        #expect(pixel0B != pixel32B)
    }

    @Test("grid produces mostly black with white lines")
    func gridProducesMostlyBlackWithWhiteLines() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        // Grid has white lines every 64 pixels; use 128x128 to test
        let data = TestPatternSource.generatePattern(.grid, width: 128, height: 128)
        var blackPixelCount = 0
        var whitePixelCount = 0
        let pixelCount = 128 * 128
        for i in 0..<pixelCount {
            let offset = i * 4
            if data[offset] == 0 && data[offset + 1] == 0 && data[offset + 2] == 0 {
                blackPixelCount += 1
            } else {
                whitePixelCount += 1
            }
        }
        // Most pixels should be black
        #expect(blackPixelCount > whitePixelCount)
    }

    @Test("grayRamp has increasing brightness left to right")
    func grayRampHasIncreasingBrightness() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let width = 256
        let data = TestPatternSource.generatePattern(.grayRamp, width: width, height: 1)
        // Left edge pixel (x=0) should be darker than right edge pixel (x=255)
        let leftBrightness = data[0]
        let rightOffset = (width - 1) * 4
        let rightBrightness = data[rightOffset]
        #expect(rightBrightness > leftBrightness)
    }

    @Test("frame data size matches resolution")
    func frameDataSizeMatchesResolution() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource(resolution: .vga, frameRate: .fps30)
        let stream = try await source.startCapture()
        var firstFrame: VideoFrame?
        for await frame in stream {
            firstFrame = frame
            break
        }
        await source.stopCapture()

        let data = try #require(firstFrame?.data)
        let expectedSize = 640 * 480 * 4
        #expect(data.count == expectedSize)
    }

    @Test("pattern can be changed")
    func patternCanBeChanged() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource(pattern: .smpteBars)
        await source.setPattern(.checkerboard)
        #expect(await source.pattern == .checkerboard)
    }

    @Test("all 10 pattern types are valid")
    func allPatternTypesAreValid() {
        #expect(TestPattern.allCases.count == 10)
    }

    @Test("startCapture and stopCapture state transitions")
    func startCaptureAndStopCaptureStateTransitions() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource(resolution: .qvga, frameRate: .fps30)
        #expect(await source.isCapturing == false)
        _ = try await source.startCapture()
        #expect(await source.isCapturing == true)
        await source.stopCapture()
        #expect(await source.isCapturing == false)
    }

    @Test("custom resolution works")
    func customResolutionWorks() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource(resolution: .p720, frameRate: .fps30)
        let formats = await source.supportedFormats
        let format = try #require(formats.first)
        #expect(format.resolution == .p720)
    }

    @Test("sequential frames have correct timestamps")
    func sequentialFramesHaveCorrectTimestamps() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource(resolution: .qvga, frameRate: .fps30)
        let stream = try await source.startCapture()
        var frames: [VideoFrame] = []
        for await frame in stream {
            frames.append(frame)
            if frames.count >= 2 { break }
        }
        await source.stopCapture()

        #expect(frames.count == 2)
        #expect(frames[1].timestamp > frames[0].timestamp)
    }

    @Test("display name is Test Pattern Generator")
    func displayNameIsTestPatternGenerator() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource()
        #expect(await source.displayName == "Test Pattern Generator")
    }

    @Test("availability is available on all platforms")
    func availabilityIsAvailable() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = TestPatternSource()
        let availability = source.availability
        #expect(availability.isAvailableOnCurrentPlatform == true)
    }
}

// MARK: - Helper Extension

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension TestPatternSource {
    fileprivate func setPattern(_ newPattern: TestPattern) {
        self.pattern = newPattern
    }
}
