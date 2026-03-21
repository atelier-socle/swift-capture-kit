// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("BlackSource", .timeLimit(.minutes(1)))
struct BlackSourceTests {

    @Test("has generator source type")
    func hasGeneratorSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource()
        #expect(await source.sourceType == .generator)
    }

    @Test("generates unique source ID")
    func generatesUniqueSourceID() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let sourceA = BlackSource()
        let sourceB = BlackSource()
        let idA = await sourceA.sourceID
        let idB = await sourceB.sourceID
        #expect(idA != idB)
    }

    @Test("default resolution is 1080p")
    func defaultResolutionIs1080p() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource()
        let formats = await source.supportedFormats
        let format = try #require(formats.first)
        #expect(format.resolution == .p1080)
    }

    @Test("default frame rate is 30fps")
    func defaultFrameRateIs30fps() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource()
        let formats = await source.supportedFormats
        let format = try #require(formats.first)
        #expect(format.frameRate == .fps30)
    }

    @Test("is not capturing initially")
    func isNotCapturingInitially() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource()
        #expect(await source.isCapturing == false)
    }

    @Test("has no active format before configure")
    func hasNoActiveFormatBeforeConfigure() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource()
        #expect(await source.activeFormat == nil)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource()
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

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource(resolution: .vga, frameRate: .fps30)
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
        await source.stopCapture()
    }

    @Test("startCapture sets isCapturing to true")
    func startCaptureSetsIsCapturing() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource(resolution: .vga, frameRate: .fps30)
        _ = try await source.startCapture()
        #expect(await source.isCapturing == true)
        await source.stopCapture()
    }

    @Test("startCapture while capturing throws")
    func startCaptureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource(resolution: .vga, frameRate: .fps30)
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
        await source.stopCapture()
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource(resolution: .vga, frameRate: .fps30)
        _ = try await source.startCapture()
        await source.stopCapture()
        #expect(await source.isCapturing == false)
    }

    @Test("produces zero-filled video frames")
    func producesZeroFilledVideoFrames() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource(resolution: .vga, frameRate: .fps30)
        let stream = try await source.startCapture()
        let firstFrame = await firstValue(from: stream)
        await source.stopCapture()

        let data = try #require(firstFrame?.data)
        let allZeros = data.allSatisfy { $0 == 0 }
        #expect(allZeros)
    }

    @Test("frame data size matches resolution")
    func frameDataSizeMatchesResolution() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource(resolution: .vga, frameRate: .fps30)
        let stream = try await source.startCapture()
        let firstFrame = await firstValue(from: stream)
        await source.stopCapture()

        let data = try #require(firstFrame?.data)
        let expectedSize = 640 * 480 * 4
        #expect(data.count == expectedSize)
    }

    @Test("sequential frames have incrementing sequence numbers")
    func sequentialFramesHaveIncrementingSequenceNumbers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource(resolution: .vga, frameRate: .fps30)
        let stream = try await source.startCapture()
        let frames = await collectValues(from: stream, count: 2)
        await source.stopCapture()

        #expect(frames.count == 2)
        #expect(frames[1].sequenceNumber > frames[0].sequenceNumber)
    }

    @Test("availability is available on all platforms")
    func availabilityIsAvailable() async {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let source = BlackSource()
        let availability = source.availability
        #expect(availability.isAvailableOnCurrentPlatform == true)
    }
}
