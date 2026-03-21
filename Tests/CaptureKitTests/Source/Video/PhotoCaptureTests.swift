// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PhotoCapture", .timeLimit(.minutes(1)))
struct PhotoCaptureTests {

    @Test("PhotoFormat CaseIterable count is 4")
    func photoFormatCaseIterableCount() {
        #expect(PhotoFormat.allCases.count == 4)
    }

    @Test("PhotoCaptureSettings defaults are flashMode .auto, hdrEnabled false, format .heif")
    func photoCaptureSettingsDefaults() {
        let settings = PhotoCaptureSettings()
        #expect(settings.flashMode == .auto)
        #expect(settings.hdrEnabled == false)
        #expect(settings.format == .heif)
    }

    @Test("CapturedPhoto init stores all values")
    func capturedPhotoInitStoresValues() {
        let photoData = Data([0x00, 0x01, 0x02])
        let photo = CapturedPhoto(
            data: photoData,
            format: .jpeg,
            timestamp: 1234.5,
            width: 1920,
            height: 1080
        )
        #expect(photo.data == photoData)
        #expect(photo.format == .jpeg)
        #expect(photo.timestamp == 1234.5)
        #expect(photo.width == 1920)
        #expect(photo.height == 1080)
    }

    @Test("PhotoFormat rawValues match expected strings")
    func photoFormatRawValues() {
        #expect(PhotoFormat.heif.rawValue == "heif")
        #expect(PhotoFormat.jpeg.rawValue == "jpeg")
        #expect(PhotoFormat.raw.rawValue == "raw")
        #expect(PhotoFormat.proRaw.rawValue == "proRaw")
    }

    @Test("PhotoCaptureSettings custom init works")
    func photoCaptureSettingsCustomInit() {
        let settings = PhotoCaptureSettings(
            flashMode: .on,
            hdrEnabled: true,
            format: .raw
        )
        #expect(settings.flashMode == .on)
        #expect(settings.hdrEnabled == true)
        #expect(settings.format == .raw)
    }
}
