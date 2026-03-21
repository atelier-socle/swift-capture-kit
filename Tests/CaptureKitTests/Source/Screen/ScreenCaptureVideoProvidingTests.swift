// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ScreenCaptureVideoProviding", .timeLimit(.minutes(1)))
struct ScreenCaptureVideoProvidingTests {

    @Test("NoOpScreenCaptureVideoProvider throws on startCapture")
    func noOpProviderThrowsOnStartCapture() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = NoOpScreenCaptureVideoProvider()
        await #expect(throws: CaptureError.self) {
            try await provider.startCapture(
                mode: .screenCaptureKit(.display(displayID: 1)))
        }
    }

    @Test("NoOpScreenCaptureVideoProvider stopCapture does not throw")
    func noOpProviderStopCaptureDoesNotThrow() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = NoOpScreenCaptureVideoProvider()
        await provider.stopCapture()
    }

    @Test("MockScreenCaptureVideoProvider tracks startCapture calls")
    func mockProviderTracksStartCaptureCalls() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        _ = try await provider.startCapture(mode: mode)
        let count = await provider.startCallCount
        #expect(count == 1)
    }

    @Test("MockScreenCaptureVideoProvider tracks stopCapture calls")
    func mockProviderTracksStopCaptureCalls() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        await provider.stopCapture()
        let count = await provider.stopCallCount
        #expect(count == 1)
    }

    @Test("MockScreenCaptureVideoProvider stores last mode")
    func mockProviderStoresLastMode() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        let mode = ScreenCaptureMode.replayKit
        _ = try await provider.startCapture(mode: mode)
        let lastMode = await provider.lastMode
        #expect(lastMode == .replayKit)
    }

    @Test("MockScreenCaptureVideoProvider emits synthetic samples")
    func mockProviderEmitsSyntheticSamples() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        let format = VideoFormat(
            resolution: .p720, frameRate: .fps30, pixelFormat: .bgra,
            colorSpace: .srgb, dynamicRange: .sdr)
        await provider.setSyntheticSamples([
            CapturedVideoSample(
                data: Data(count: 100), timestamp: 0.0,
                format: format, isKeyFrame: true)
        ])
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        let stream = try await provider.startCapture(mode: mode)
        var count = 0
        for await _ in stream { count += 1 }
        #expect(count == 1)
    }

    @Test("MockScreenCaptureVideoProvider can throw on start")
    func mockProviderCanThrowOnStart() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        await provider.setShouldThrowOnStart(true)
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        await #expect(throws: CaptureError.self) {
            try await provider.startCapture(mode: mode)
        }
    }
}

extension MockScreenCaptureVideoProvider {
    func setShouldThrowOnStart(_ value: Bool) {
        self.shouldThrowOnStart = value
    }
}
