// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("VideoSource")
struct VideoSourceTests {

    @Test("MockVideoSource conforms to VideoSource protocol")
    func mockConformsToProtocol() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = MockVideoSource()
        #expect(source.sourceID == "mock-video")
        #expect(source.displayName == "Mock Video")
        #expect(source.sourceType == .builtInCamera)
        #expect(source.availability == .available)

        try await source.configure(.default)
        let configCount = await source.configureCallCount
        #expect(configCount == 1)

        let stream = try await source.startCapture()
        _ = stream
        let startCount = await source.startCaptureCallCount
        #expect(startCount == 1)

        let isCapturing = await source.isCapturing
        #expect(isCapturing == true)

        await source.stopCapture()
        let stopCount = await source.stopCaptureCallCount
        #expect(stopCount == 1)

        let isStopped = await source.isCapturing
        #expect(isStopped == false)
    }

    @Test("VideoSourceType CaseIterable count is eight")
    func videoSourceTypeCaseCount() {
        #expect(VideoSourceType.allCases.count == 8)
    }

    @Test("VideoStabilization CaseIterable count is six")
    func videoStabilizationCaseCount() {
        #expect(VideoStabilization.allCases.count == 6)
    }

    @Test("FocusMode CaseIterable count is four")
    func focusModeCaseCount() {
        #expect(FocusMode.allCases.count == 4)
    }

    @Test("ExposureMode CaseIterable count is four")
    func exposureModeCaseCount() {
        #expect(ExposureMode.allCases.count == 4)
    }

    @Test("VideoSourceConfiguration default preset values")
    func defaultConfiguration() {
        let config = VideoSourceConfiguration.default
        #expect(config.resolution == .p1080)
        #expect(config.frameRate == .fps30)
        #expect(config.pixelFormat == .nv12)
        #expect(config.colorSpace == .bt709)
        #expect(config.dynamicRange == .sdr)
        #expect(config.stabilization == .off)
        #expect(config.focusMode == .continuousAutoFocus)
        #expect(config.exposureMode == .continuousAutoExposure)
        #expect(config.whiteBalanceMode == .continuousAutoWhiteBalance)
    }

    @Test("FrameStatisticsSample init and Equatable")
    func frameStatisticsSampleInitAndEquatable() {
        let a = FrameStatisticsSample(
            timestamp: 1.0,
            capturedFrameRate: 30.0,
            droppedFrames: 2,
            encodedFrameRate: 29.5,
            averageEncodingTime: 0.005,
            currentBitrate: 5_000_000,
            keyFrameInterval: 60,
            bufferLevel: 10
        )
        let b = FrameStatisticsSample(
            timestamp: 1.0,
            capturedFrameRate: 30.0,
            droppedFrames: 2,
            encodedFrameRate: 29.5,
            averageEncodingTime: 0.005,
            currentBitrate: 5_000_000,
            keyFrameInterval: 60,
            bufferLevel: 10
        )
        #expect(a == b)
        #expect(a.timestamp == 1.0)
        #expect(a.capturedFrameRate == 30.0)
        #expect(a.droppedFrames == 2)
        #expect(a.encodedFrameRate == 29.5)
        #expect(a.averageEncodingTime == 0.005)
        #expect(a.currentBitrate == 5_000_000)
        #expect(a.keyFrameInterval == 60)
        #expect(a.bufferLevel == 10)
    }
}
