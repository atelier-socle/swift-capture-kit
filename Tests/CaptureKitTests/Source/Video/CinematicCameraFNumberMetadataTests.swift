// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CinematicCameraSource F-Number Metadata", .timeLimit(.minutes(1)))
struct CinematicCameraFNumberMetadataTests {

    @Test("fNumber included in frame metadata")
    func fNumberIncludedInFrameMetadata() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let engine = MockVideoCaptureEngine()
        let source = CinematicCameraSource(captureEngine: engine)
        await source.setFNumber(5.6)
        let stream = try await source.startCapture()
        for await frame in stream {
            #expect(frame.metadata["fNumber"] != nil)
            #expect(frame.metadata["fNumber"] == "5.6")
            break
        }
        await source.stopCapture()
    }

    @Test("default fNumber is 2.8")
    func defaultFNumber() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource(captureEngine: MockVideoCaptureEngine())
        let fNumber = await source.fNumber
        #expect(fNumber == 2.8)
    }

    @Test("fNumber clamped to range")
    func fNumberClampedToRange() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let source = CinematicCameraSource(captureEngine: MockVideoCaptureEngine())

        await source.setFNumber(0.5)
        let low = await source.fNumber
        #expect(low == 1.4)

        await source.setFNumber(32.0)
        let high = await source.fNumber
        #expect(high == 16.0)
    }
}
