// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ScreenCaptureSource")
struct ScreenCaptureSourceTests {

    @Test("has screenCapture source type")
    func hasScreenCaptureSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        #expect(await source.sourceType == .screenCapture)
    }

    @Test("generates unique source ID")
    func generatesUniqueSourceID() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source1 = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        let source2 = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 2)))
        let id1 = await source1.sourceID
        let id2 = await source2.sourceID
        #expect(id1 != id2)
    }

    @Test("display name reflects screenCaptureKit mode")
    func displayNameReflectsScreenCaptureKitMode() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        let name = await source.displayName
        #expect(name == "Screen Capture (macOS)")
    }

    @Test("display name reflects replayKit mode")
    func displayNameReflectsReplayKitMode() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .replayKit)
        let name = await source.displayName
        #expect(name == "Screen Recording (In-App)")
    }

    @Test("display name reflects broadcastExtension mode")
    func displayNameReflectsBroadcastExtensionMode() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .broadcastExtension(appGroupID: "group.test"))
        let name = await source.displayName
        #expect(name == "Screen Broadcast")
    }

    @Test("is not capturing initially")
    func isNotCapturingInitially() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        #expect(await source.isCapturing == false)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
            try await source.configure(.default)
            #expect(await source.activeFormat != nil)
        #endif
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        let source = ScreenCaptureSource(mode: mode, videoProvider: provider)
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
        await source.stopCapture()
    }

    @Test("startCapture sets isCapturing to true")
    func startCaptureSetsIsCapturingToTrue() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        let source = ScreenCaptureSource(mode: mode, videoProvider: provider)
        _ = try await source.startCapture()
        #expect(await source.isCapturing == true)
        await source.stopCapture()
    }

    @Test("startCapture while capturing throws")
    func startCaptureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        let source = ScreenCaptureSource(mode: mode, videoProvider: provider)
        _ = try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            try await source.startCapture()
        }
        await source.stopCapture()
    }

    @Test("stopCapture sets isCapturing to false")
    func stopCaptureSetsIsCapturingToFalse() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        let source = ScreenCaptureSource(mode: mode, videoProvider: provider)
        _ = try await source.startCapture()
        await source.stopCapture()
        #expect(await source.isCapturing == false)
    }

    @Test("startCapture produces video frames from provider")
    func startCaptureProducesVideoFrames() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        let format = VideoFormat(
            resolution: .p1080, frameRate: .fps30, pixelFormat: .bgra,
            colorSpace: .srgb, dynamicRange: .sdr)
        await provider.setSyntheticSamples([
            CapturedVideoSample(
                data: Data(count: 1920 * 1080 * 4),
                timestamp: 0.0, format: format, isKeyFrame: true),
            CapturedVideoSample(
                data: Data(count: 1920 * 1080 * 4),
                timestamp: 0.033, format: format, isKeyFrame: true)
        ])
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        let source = ScreenCaptureSource(mode: mode, videoProvider: provider)
        let stream = try await source.startCapture()
        var count = 0
        for await _ in stream {
            count += 1
        }
        #expect(count == 2)
        await source.stopCapture()
    }

    @Test("stopCapture calls provider stopCapture")
    func stopCaptureCallsProviderStop() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let provider = MockScreenCaptureVideoProvider()
        let mode = ScreenCaptureMode.screenCaptureKit(.display(displayID: 1))
        let source = ScreenCaptureSource(mode: mode, videoProvider: provider)
        _ = try await source.startCapture()
        await source.stopCapture()
        let stopCount = await provider.stopCallCount
        #expect(stopCount == 1)
    }

    @Test("replayKit mode throws on macOS")
    func replayKitModeThrowsOnMacOS() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .replayKit)
            await #expect(throws: CaptureError.self) {
                try await source.configure(.default)
            }
        #endif
    }

    @Test("broadcastExtension mode throws on macOS")
    func broadcastExtensionModeThrowsOnMacOS() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .broadcastExtension(appGroupID: "group.test"))
            await #expect(throws: CaptureError.self) {
                try await source.configure(.default)
            }
        #endif
    }

    @Test("screenCaptureKit configuration is settable")
    func screenCaptureKitConfigurationIsSettable() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
        let config = await source.screenCaptureKitConfiguration
        #expect(config == .default)
    }

    @Test("availability requires screen recording on macOS")
    func availabilityRequiresScreenRecordingOnMacOS() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        #if os(macOS)
            let source = ScreenCaptureSource(mode: .screenCaptureKit(.display(displayID: 1)))
            let availability = source.availability
            #expect(availability.requiredPermissions.contains(.screenRecording))
        #endif
    }
}

extension MockScreenCaptureVideoProvider {
    func setSyntheticSamples(_ samples: [CapturedVideoSample]) {
        self.syntheticSamples = samples
    }
}
