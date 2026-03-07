// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PhotoCaptureSettings")
struct PhotoCaptureSettingsTests {

    @Test("PhotoFormat allCases has four members")
    func photoFormatAllCasesCount() {
        #expect(PhotoFormat.allCases.count == 4)
    }

    @Test("PhotoFormat rawValue roundtrips correctly")
    func photoFormatRawValueRoundtrips() {
        for format in PhotoFormat.allCases {
            let roundtripped = PhotoFormat(rawValue: format.rawValue)
            #expect(roundtripped == format)
        }
    }

    @Test("default PhotoCaptureSettings has expected values")
    func defaultPhotoCaptureSettings() {
        let settings = PhotoCaptureSettings()
        #expect(settings.flashMode == .auto)
        #expect(settings.hdrEnabled == false)
        #expect(settings.format == .heif)
    }

    @Test("custom PhotoCaptureSettings stores provided values")
    func customPhotoCaptureSettings() {
        let settings = PhotoCaptureSettings(
            flashMode: .on,
            hdrEnabled: true,
            format: .jpeg
        )
        #expect(settings.flashMode == .on)
        #expect(settings.hdrEnabled == true)
        #expect(settings.format == .jpeg)
    }

    @Test("CapturedPhoto stores data correctly")
    func capturedPhotoStoresData() {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let photo = CapturedPhoto(
            data: data, format: .jpeg, timestamp: 1.0, width: 100, height: 200
        )
        #expect(photo.data == data)
    }

    @Test("CapturedPhoto stores dimensions correctly")
    func capturedPhotoStoresDimensions() {
        let photo = CapturedPhoto(
            data: Data(), format: .heif, timestamp: 0.0, width: 1920, height: 1080
        )
        #expect(photo.width == 1920)
        #expect(photo.height == 1080)
    }

    @Test("CapturedPhoto stores format correctly")
    func capturedPhotoStoresFormat() {
        let photo = CapturedPhoto(
            data: Data(), format: .raw, timestamp: 0.0, width: 100, height: 100
        )
        #expect(photo.format == .raw)
    }

    @Test("CapturedPhoto stores timestamp correctly")
    func capturedPhotoStoresTimestamp() {
        let timestamp: TimeInterval = 42.5
        let photo = CapturedPhoto(
            data: Data(), format: .heif, timestamp: timestamp, width: 100, height: 100
        )
        #expect(photo.timestamp == timestamp)
    }

    @Test("PhotoFormat conforms to Sendable")
    func photoFormatIsSendable() {
        let format: any Sendable = PhotoFormat.jpeg
        #expect(format is PhotoFormat)
    }

    @Test("PhotoCaptureSettings conforms to Sendable")
    func photoCaptureSettingsIsSendable() {
        let settings: any Sendable = PhotoCaptureSettings()
        #expect(settings is PhotoCaptureSettings)
    }

    @Test("PhotoFormat rawValues match expected strings")
    func photoFormatRawValues() {
        #expect(PhotoFormat.heif.rawValue == "heif")
        #expect(PhotoFormat.jpeg.rawValue == "jpeg")
        #expect(PhotoFormat.raw.rawValue == "raw")
        #expect(PhotoFormat.proRaw.rawValue == "proRaw")
    }

    @Test("CapturedPhoto with proRaw format")
    func capturedPhotoWithProRaw() {
        let photo = CapturedPhoto(
            data: Data([0x01]), format: .proRaw, timestamp: 3.14, width: 4032, height: 3024
        )
        #expect(photo.format == .proRaw)
        #expect(photo.width == 4032)
        #expect(photo.height == 3024)
    }
}
