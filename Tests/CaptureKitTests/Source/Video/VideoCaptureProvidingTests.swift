// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("VideoCaptureProviding new protocol methods")
struct VideoCaptureProvidingTests {

    @Test("setDepthDataDelivery tracks enabled state")
    func setDepthDataDeliveryTracksEnabled() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        try await engine.setDepthDataDelivery(true)
        let enabled = await engine.depthDataDeliveryEnabled
        #expect(enabled == true)
    }

    @Test("applyContinuityFeatures tracks features")
    func applyContinuityFeaturesTracksFeatures() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let features = ContinuityCameraFeatures(
            centerStage: true, portraitMode: true, studioLight: false)
        try await engine.applyContinuityFeatures(features)
        let applied = await engine.lastContinuityFeatures
        #expect(applied?.centerStage == true)
        #expect(applied?.portraitMode == true)
        #expect(applied?.studioLight == false)
    }

    @Test("setFocusPointOfInterest tracks coordinates")
    func setFocusPointOfInterestTracksCoordinates() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        try await engine.setFocusPointOfInterest(x: 0.25, y: 0.75)
        let point = await engine.lastFocusPoint
        #expect(point?.x == 0.25)
        #expect(point?.y == 0.75)
    }

    @Test("setFocusMode tracks mode")
    func setFocusModeTracksMode() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        try await engine.setFocusMode(.locked)
        let mode = await engine.lastFocusMode
        #expect(mode == .locked)
    }

    @Test("capturePhoto returns mock photo data")
    func capturePhotoReturnsMockData() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let photo = try await engine.capturePhoto(settings: nil)
        #expect(photo.format == .jpeg)
        #expect(photo.width == 1920)
        #expect(photo.height == 1080)
        #expect(photo.data.count > 0)
    }

    @Test("capturePhoto with settings tracks settings")
    func capturePhotoWithSettingsTracksSettings() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let settings = PhotoCaptureSettings(flashMode: .on)
        _ = try await engine.capturePhoto(settings: settings)
        let captured = await engine.lastPhotoSettings
        #expect(captured?.flashMode == .on)
    }
}
