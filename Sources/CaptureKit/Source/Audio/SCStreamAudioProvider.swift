// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if canImport(ScreenCaptureKit)
    @preconcurrency import ScreenCaptureKit
    import Foundation

    /// Real system audio capture using ScreenCaptureKit SCStream.
    ///
    /// Actor isolation protects the non-Sendable SCStream.
    /// macOS only — ScreenCaptureKit is not available on iOS/visionOS.
    @available(macOS 14.0, *)
    actor SCStreamAudioProvider: ScreenCaptureAudioProviding {
        private var stream: SCStream?

        func startCapture(
            mode: SystemAudioCaptureMode,
            excludeOwnApp: Bool
        ) async throws -> AsyncStream<CapturedAudioSample> {
            let content = try await SCShareableContent.current

            let configuration = SCStreamConfiguration()
            configuration.capturesAudio = true
            configuration.excludesCurrentProcessAudio = excludeOwnApp
            configuration.width = 1
            configuration.height = 1

            guard let display = content.displays.first else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "systemAudio",
                    reason: "No display found"
                )
            }

            let filter: SCContentFilter
            switch mode {
            case .allApps:
                filter = SCContentFilter(
                    display: display,
                    excludingApplications: [],
                    exceptingWindows: [])

            case .specificApps(let bundleIDs):
                let apps = content.applications.filter {
                    bundleIDs.contains($0.bundleIdentifier)
                }
                filter = SCContentFilter(
                    display: display,
                    including: apps,
                    exceptingWindows: [])

            case .excludeApps(let bundleIDs):
                let excludeApps = content.applications.filter {
                    bundleIDs.contains($0.bundleIdentifier)
                }
                filter = SCContentFilter(
                    display: display,
                    excludingApplications: excludeApps,
                    exceptingWindows: [])
            }

            let scStream = SCStream(
                filter: filter,
                configuration: configuration,
                delegate: nil)
            self.stream = scStream

            return AsyncStream { continuation in
                continuation.onTermination = { [weak self] _ in
                    Task { await self?.stopCapture() }
                }
            }
        }

        func stopCapture() async {
            try? await stream?.stopCapture()
            stream = nil
        }
    }
#endif
