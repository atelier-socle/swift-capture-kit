// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

#if os(macOS)

    @Suite("SystemAudioSource", .timeLimit(.minutes(1)))
    struct SystemAudioSourceTests {

        @Test("has systemAudio source type")
        func sourceType() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = SystemAudioSource()
            let type = await source.sourceType
            #expect(type == .systemAudio)
        }

        @Test("default capture mode is allApps")
        func defaultCaptureModeIsAllApps() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = SystemAudioSource()
            let mode = await source.captureMode
            #expect(mode == .allApps)
        }

        @Test("excludeOwnApp defaults to true")
        func excludeOwnAppDefaultsToTrue() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = SystemAudioSource()
            let excludeOwn = await source.excludeOwnApp
            #expect(excludeOwn == true)
        }

        @Test("configure sets active format")
        func configureSetsActiveFormat() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = SystemAudioSource()
            try await source.configure(.default)
            let format = await source.activeFormat
            #expect(format != nil)
            #expect(format?.sampleRate == .rate48000)
            #expect(format?.channelCount == 2)
        }

        @Test("availability requires screenRecording permission")
        func availabilityRequiresScreenRecordingPermission() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = SystemAudioSource()
            let availability = source.availability
            #expect(availability.requiredPermissions.contains(.screenRecording))
        }

        @Test("availability notes mention macOS")
        func availabilityNotesMentionMacOS() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = SystemAudioSource()
            let availability = source.availability
            #expect(availability.notes != nil)
            #expect(availability.notes?.contains("macOS") == true)
        }

        @Test("is not capturing initially")
        func notCapturingInitially() async throws {
            guard #available(macOS 14.0, *) else { return }

            let source = SystemAudioSource()
            let capturing = await source.isCapturing
            #expect(capturing == false)
        }

        @Test("stopCapture sets isCapturing to false")
        func stopCaptureSetsIsCapturingToFalse() async throws {
            guard #available(macOS 14.0, *) else { return }

            let mockProvider = MockScreenCaptureAudioProvider()
            let source = SystemAudioSource(
                audioProvider: mockProvider)
            _ = try await source.startCapture()
            let capturing = await source.isCapturing
            #expect(capturing == true)

            await source.stopCapture()
            let stopped = await source.isCapturing
            #expect(stopped == false)
        }
    }

#endif
