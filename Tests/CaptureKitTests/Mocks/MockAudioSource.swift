// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockAudioSource: AudioSource {
    let sourceID: String
    let displayName: String
    let sourceType: AudioSourceType
    nonisolated let availability: SourceAvailability

    private var _supportedFormats: [AudioFormat] = []
    private var _activeFormat: AudioFormat?
    private var _isCapturing = false
    private(set) var configureCallCount = 0
    private(set) var startCaptureCallCount = 0
    private(set) var stopCaptureCallCount = 0

    var supportedFormats: [AudioFormat] { _supportedFormats }
    var activeFormat: AudioFormat? { _activeFormat }
    var isCapturing: Bool { _isCapturing }

    nonisolated var audioLevel: AsyncStream<AudioLevelSample> {
        AsyncStream { continuation in continuation.finish() }
    }

    init(
        sourceID: String = "mock-audio",
        displayName: String = "Mock Audio",
        sourceType: AudioSourceType = .microphone,
        availability: SourceAvailability = .available
    ) {
        self.sourceID = sourceID
        self.displayName = displayName
        self.sourceType = sourceType
        self.availability = availability
    }

    func configure(_ configuration: AudioSourceConfiguration) async throws {
        configureCallCount += 1
        _activeFormat = AudioFormat(
            sampleRate: configuration.sampleRate,
            channelCount: configuration.channelCount,
            channelLayout: configuration.channelLayout,
            bitDepth: configuration.bitDepth
        )
    }

    func startCapture() async throws -> AsyncStream<AudioBuffer> {
        startCaptureCallCount += 1
        _isCapturing = true
        return AsyncStream { continuation in continuation.finish() }
    }

    func stopCapture() async {
        stopCaptureCallCount += 1
        _isCapturing = false
    }

    func setSupportedFormats(_ formats: [AudioFormat]) {
        _supportedFormats = formats
    }
}
