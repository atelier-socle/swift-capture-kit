// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileMetadata", .timeLimit(.minutes(1)))
struct FileMetadataTests {

    @Test("default values are nil and empty")
    func defaultValues() {
        let metadata = FileMetadata()
        #expect(metadata.title == nil)
        #expect(metadata.artist == nil)
        #expect(metadata.album == nil)
        #expect(metadata.comment == nil)
        #expect(metadata.creationDate == nil)
        #expect(metadata.custom.isEmpty)
    }

    @Test("custom values are stored")
    func customValues() {
        let date = Date()
        let metadata = FileMetadata(
            title: "Test Recording",
            artist: "Tester",
            album: "Tests",
            comment: "A test",
            creationDate: date,
            custom: ["key": "value"]
        )
        #expect(metadata.title == "Test Recording")
        #expect(metadata.artist == "Tester")
        #expect(metadata.album == "Tests")
        #expect(metadata.comment == "A test")
        #expect(metadata.creationDate == date)
        #expect(metadata.custom["key"] == "value")
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = FileMetadata(title: "A")
        let b = FileMetadata(title: "A")
        #expect(a == b)
    }

    @Test("different titles are not equal")
    func differentTitles() {
        let a = FileMetadata(title: "A")
        let b = FileMetadata(title: "B")
        #expect(a != b)
    }

    @Test("Sendable conformance compiles")
    func sendableConformance() {
        let metadata = FileMetadata(title: "Test")
        let _: any Sendable = metadata
    }
}
