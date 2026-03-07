// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileRotationConfiguration")
struct FileRotationConfigurationTests {

    @Test("byDuration factory method")
    func byDuration() {
        let config = FileRotationConfiguration.byDuration(60)
        #expect(config.trigger == .duration(60))
        #expect(config.maxFiles == nil)
        #expect(config.namingPattern == .timestamp)
    }

    @Test("bySize factory method")
    func bySize() {
        let config = FileRotationConfiguration.bySize(10_000_000)
        #expect(config.trigger == .size(10_000_000))
        #expect(config.maxFiles == nil)
    }

    @Test("byDuration with maxFiles")
    func byDurationWithMaxFiles() {
        let config = FileRotationConfiguration.byDuration(
            300, maxFiles: 10)
        #expect(config.maxFiles == 10)
    }

    @Test("bySize with maxFiles")
    func bySizeWithMaxFiles() {
        let config = FileRotationConfiguration.bySize(
            5_000_000, maxFiles: 5)
        #expect(config.maxFiles == 5)
    }

    @Test("durationOrSize trigger")
    func durationOrSizeTrigger() {
        let config = FileRotationConfiguration(
            trigger: .durationOrSize(duration: 120, size: 50_000_000))
        #expect(
            config.trigger
                == .durationOrSize(duration: 120, size: 50_000_000))
    }

    @Test("default naming is timestamp")
    func defaultNaming() {
        let config = FileRotationConfiguration(trigger: .duration(60))
        #expect(config.namingPattern == .timestamp)
    }

    @Test("custom naming pattern")
    func customNaming() {
        let config = FileRotationConfiguration(
            trigger: .duration(60),
            namingPattern: .sequential
        )
        #expect(config.namingPattern == .sequential)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = FileRotationConfiguration.byDuration(60)
        let b = FileRotationConfiguration.byDuration(60)
        #expect(a == b)
    }
}
