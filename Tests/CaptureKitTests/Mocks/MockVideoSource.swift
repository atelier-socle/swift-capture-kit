// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockVideoSource: VideoSource {
    let sourceID: String
    let displayName: String
    let sourceType: VideoSourceType
    nonisolated let availability: SourceAvailability

    private var _supportedFormats: [VideoFormat] = []
    private var _activeFormat: VideoFormat?
    private var _isCapturing = false
    private(set) var configureCallCount = 0
    private(set) var startCaptureCallCount = 0
    private(set) var stopCaptureCallCount = 0

    var supportedFormats: [VideoFormat] { _supportedFormats }
    var activeFormat: VideoFormat? { _activeFormat }
    var isCapturing: Bool { _isCapturing }

    nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        AsyncStream { continuation in continuation.finish() }
    }

    init(
        sourceID: String = "mock-video",
        displayName: String = "Mock Video",
        sourceType: VideoSourceType = .builtInCamera,
        availability: SourceAvailability = .available
    ) {
        self.sourceID = sourceID
        self.displayName = displayName
        self.sourceType = sourceType
        self.availability = availability
    }

    func configure(_ configuration: VideoSourceConfiguration) async throws {
        configureCallCount += 1
        _activeFormat = VideoFormat(
            resolution: configuration.resolution,
            frameRate: configuration.frameRate,
            pixelFormat: configuration.pixelFormat,
            colorSpace: configuration.colorSpace,
            dynamicRange: configuration.dynamicRange
        )
    }

    func startCapture() async throws -> AsyncStream<VideoFrame> {
        startCaptureCallCount += 1
        _isCapturing = true
        return AsyncStream { continuation in continuation.finish() }
    }

    func stopCapture() async {
        stopCaptureCallCount += 1
        _isCapturing = false
    }

    func setSupportedFormats(_ formats: [VideoFormat]) {
        _supportedFormats = formats
    }
}
