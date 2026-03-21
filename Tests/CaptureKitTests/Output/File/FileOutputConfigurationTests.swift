// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileOutputConfiguration", .timeLimit(.minutes(1)))
struct FileOutputConfigurationTests {

    @Test("initializes with URL and container")
    func initializesWithURLAndContainer() {
        let url = URL(filePath: "/tmp/test.mp4")
        let config = FileOutputConfiguration(url: url, container: .mp4)
        #expect(config.url == url)
        #expect(config.container == .mp4)
    }

    @Test("default overwrite is false")
    func defaultOverwriteIsFalse() {
        let config = FileOutputConfiguration(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        #expect(config.overwriteExisting == false)
    }

    @Test("default metadata is nil")
    func defaultMetadataIsNil() {
        let config = FileOutputConfiguration(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        #expect(config.metadata == nil)
    }

    @Test("default rotation is nil")
    func defaultRotationIsNil() {
        let config = FileOutputConfiguration(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        #expect(config.rotation == nil)
    }

    @Test("custom values are stored")
    func customValuesAreStored() {
        let url = URL(filePath: "/tmp/recording.mov")
        let metadata = FileMetadata(title: "Test")
        let rotation = FileRotationConfiguration.byDuration(60)
        let config = FileOutputConfiguration(
            url: url,
            container: .mov,
            metadata: metadata,
            overwriteExisting: true,
            rotation: rotation
        )
        #expect(config.url == url)
        #expect(config.container == .mov)
        #expect(config.metadata == metadata)
        #expect(config.overwriteExisting == true)
        #expect(config.rotation == rotation)
    }

    @Test("Equatable conformance")
    func equatableConformance() {
        let url = URL(filePath: "/tmp/test.mp4")
        let a = FileOutputConfiguration(url: url, container: .mp4)
        let b = FileOutputConfiguration(url: url, container: .mp4)
        #expect(a == b)
    }

    @Test("different containers are not equal")
    func differentContainersNotEqual() {
        let url = URL(filePath: "/tmp/test.mp4")
        let a = FileOutputConfiguration(url: url, container: .mp4)
        let b = FileOutputConfiguration(url: url, container: .mov)
        #expect(a != b)
    }

    @Test("Sendable conformance compiles")
    func sendableConformance() {
        let config = FileOutputConfiguration(
            url: URL(filePath: "/tmp/test.mp4"), container: .mp4)
        let _: any Sendable = config
    }
}
