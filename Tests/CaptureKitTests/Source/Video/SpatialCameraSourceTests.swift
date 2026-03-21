// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if os(visionOS)
    import Foundation
    import Testing

    @testable import CaptureKit

    @Suite("SpatialCameraSource", .timeLimit(.minutes(1)))
    struct SpatialCameraSourceTests {

        @Test("has spatialCamera source type")
        func sourceType() async throws {
            let source = SpatialCameraSource()
            let type = await source.sourceType
            #expect(type == .spatialCamera)
        }

        @Test("default mode is stereoscopic")
        func defaultModeIsStereoscopic() async throws {
            let source = SpatialCameraSource()
            let mode = await source.spatialMode
            #expect(mode == .stereoscopic)
        }

        @Test("mode can be set via initializer")
        func modeCanBeSetViaInitializer() async throws {
            let source = SpatialCameraSource(mode: .monoFallback)
            let mode = await source.spatialMode
            #expect(mode == .monoFallback)
        }

        @Test("availability requires camera permission")
        func availabilityRequiresCameraPermission() async throws {
            let source = SpatialCameraSource()
            let availability = source.availability
            #expect(availability.requiredPermissions.contains(.camera))
        }

        @Test("configure sets active format")
        func configureSetsActiveFormat() async throws {
            let source = SpatialCameraSource()
            try await source.configure(.spatialVideo)
            let format = await source.activeFormat
            #expect(format != nil)
        }

        @Test("startCapture and stopCapture state transitions")
        func startAndStopCaptureStateTransitions() async throws {
            let source = SpatialCameraSource(captureEngine: MockVideoCaptureEngine())

            let initialCapturing = await source.isCapturing
            #expect(initialCapturing == false)

            _ = try await source.startCapture()
            let capturing = await source.isCapturing
            #expect(capturing == true)

            await source.stopCapture()
            let stopped = await source.isCapturing
            #expect(stopped == false)
        }
    }
#endif
