// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("BroadcastSource")
struct BroadcastSourceTests {

    @Test("has screenCapture source type")
    func hasScreenCaptureSourceType() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        #expect(await source.sourceType == .screenCapture)
    }

    @Test("stores broadcast configuration")
    func storesBroadcastConfiguration() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        #expect(await source.broadcastConfiguration.appGroupID == "group.test")
    }

    @Test("creates IPC channel with correct appGroupID")
    func createsIPCChannelWithCorrectAppGroupID() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        #expect(await source.ipcChannel.appGroupID == "group.test")
    }

    @Test("is not capturing initially")
    func isNotCapturingInitially() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        #expect(await source.isCapturing == false)
    }

    @Test("configure sets active format")
    func configureSetsActiveFormat() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        try await source.configure(.default)
        #expect(await source.activeFormat != nil)
    }

    @Test("configure while capturing throws")
    func configureWhileCapturingThrows() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        try await source.configure(.default)
        try await source.startCapture()
        await #expect(throws: CaptureError.self) {
            try await source.configure(.default)
        }
        try await source.stopCapture()
    }

    @Test("startCapture connects IPC channel")
    func startCaptureConnectsIPCChannel() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        try await source.configure(.default)
        try await source.startCapture()
        #expect(await source.ipcChannel.isConnected == true)
        try await source.stopCapture()
    }

    @Test("startCapture sets isCapturing to true")
    func startCaptureSetsIsCapturingToTrue() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        try await source.configure(.default)
        try await source.startCapture()
        #expect(await source.isCapturing == true)
        try await source.stopCapture()
    }

    @Test("stopCapture disconnects IPC channel")
    func stopCaptureDisconnectsIPCChannel() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        try await source.configure(.default)
        try await source.startCapture()
        try await source.stopCapture()
        #expect(await source.ipcChannel.isConnected == false)
    }

    @Test("availability notes mention Broadcast Extension")
    func availabilityNotesMentionBroadcastExtension() async {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }
        let config = BroadcastConfiguration(appGroupID: "group.test")
        let source = BroadcastSource(configuration: config)
        let availability = await source.availability
        #expect(availability.notes?.contains("Broadcast") == true)
    }
}
