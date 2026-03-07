// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ColorSource")
struct ColorSourceTests {

    @Test("has generator source type")
    func hasGeneratorSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .red)
        #expect(await source.sourceType == .generator)
    }

    @Test("stores configured color")
    func storesConfiguredColor() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .blue)
        #expect(await source.color == .blue)
    }

    @Test("default resolution is 1080p")
    func defaultResolutionIs1080p() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .red)
        let formats = await source.supportedFormats
        let format = try #require(formats.first)
        #expect(format.resolution == .p1080)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .red)
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

    @Test("produces non-zero frames for non-black colors")
    func producesNonZeroFramesForNonBlackColors() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .red, resolution: .qvga, frameRate: .fps30)
        let stream = try await source.startCapture()
        var firstFrame: VideoFrame?
        for await frame in stream {
            firstFrame = frame
            break
        }
        await source.stopCapture()

        let data = try #require(firstFrame?.data)
        let hasNonZero = data.contains { $0 != 0 }
        #expect(hasNonZero)
    }

    @Test("red color produces correct BGRA bytes")
    func redColorProducesCorrectBGRABytes() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .red, resolution: .qvga, frameRate: .fps30)
        let stream = try await source.startCapture()
        var firstFrame: VideoFrame?
        for await frame in stream {
            firstFrame = frame
            break
        }
        await source.stopCapture()

        let data = try #require(firstFrame?.data)
        // BGRA for red: B=0, G=0, R=255, A=255
        #expect(data[0] == 0)
        #expect(data[1] == 0)
        #expect(data[2] == 255)
        #expect(data[3] == 255)
    }

    @Test("white color fills all channels")
    func whiteColorFillsAllChannels() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .white, resolution: .qvga, frameRate: .fps30)
        let stream = try await source.startCapture()
        var firstFrame: VideoFrame?
        for await frame in stream {
            firstFrame = frame
            break
        }
        await source.stopCapture()

        let data = try #require(firstFrame?.data)
        // BGRA for white: B=255, G=255, R=255, A=255
        #expect(data[0] == 255)
        #expect(data[1] == 255)
        #expect(data[2] == 255)
        #expect(data[3] == 255)
    }

    @Test("frame data size matches resolution")
    func frameDataSizeMatchesResolution() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .green, resolution: .vga, frameRate: .fps30)
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

    @Test("color can be changed")
    func colorCanBeChanged() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .red)
        await source.setColor(.blue)
        #expect(await source.color == .blue)
    }

    @Test("startCapture and stopCapture state transitions")
    func startCaptureAndStopCaptureStateTransitions() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .red, resolution: .qvga, frameRate: .fps30)
        #expect(await source.isCapturing == false)
        _ = try await source.startCapture()
        #expect(await source.isCapturing == true)
        await source.stopCapture()
        #expect(await source.isCapturing == false)
    }

    @Test("custom resolution works")
    func customResolutionWorks() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = ColorSource(color: .red, resolution: .p720, frameRate: .fps30)
        let formats = await source.supportedFormats
        let format = try #require(formats.first)
        #expect(format.resolution == .p720)
    }

    @Test("alpha channel is preserved")
    func alphaChannelIsPreserved() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let halfAlphaColor = CaptureColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
        let source = ColorSource(color: halfAlphaColor, resolution: .qvga, frameRate: .fps30)
        let stream = try await source.startCapture()
        var firstFrame: VideoFrame?
        for await frame in stream {
            firstFrame = frame
            break
        }
        await source.stopCapture()

        let data = try #require(firstFrame?.data)
        // Alpha should be approximately 127 (0.5 * 255 = 127)
        let alpha = data[3]
        #expect(alpha == 127)
    }

    @Test("static color constants are correct")
    func staticColorConstantsAreCorrect() {
        #expect(CaptureColor.black == CaptureColor(red: 0, green: 0, blue: 0))
        #expect(CaptureColor.white == CaptureColor(red: 1, green: 1, blue: 1))
        #expect(CaptureColor.red == CaptureColor(red: 1, green: 0, blue: 0))
        #expect(CaptureColor.green == CaptureColor(red: 0, green: 1, blue: 0))
        #expect(CaptureColor.blue == CaptureColor(red: 0, green: 0, blue: 1))
        #expect(CaptureColor.gray == CaptureColor(red: 0.5, green: 0.5, blue: 0.5))
    }

    @Test("CaptureColor equality works")
    func captureColorEqualityWorks() {
        let colorA = CaptureColor(red: 0.5, green: 0.3, blue: 0.7)
        let colorB = CaptureColor(red: 0.5, green: 0.3, blue: 0.7)
        let colorC = CaptureColor(red: 0.1, green: 0.2, blue: 0.3)
        #expect(colorA == colorB)
        #expect(colorA != colorC)
    }

    @Test("CaptureColor hashing works")
    func captureColorHashingWorks() {
        let colorA = CaptureColor(red: 1.0, green: 0.0, blue: 0.0)
        let colorB = CaptureColor(red: 0.0, green: 1.0, blue: 0.0)
        let colorC = CaptureColor(red: 1.0, green: 0.0, blue: 0.0)
        var colorSet = Set<CaptureColor>()
        colorSet.insert(colorA)
        colorSet.insert(colorB)
        colorSet.insert(colorC)
        #expect(colorSet.count == 2)
    }
}

// MARK: - Helper Extension

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension ColorSource {
    fileprivate func setColor(_ newColor: CaptureColor) {
        self.color = newColor
    }
}
