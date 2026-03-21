// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("RecordingStatistics", .timeLimit(.minutes(1)))
struct RecordingStatisticsTests {

    @Test("zero preset has all zeros")
    func zeroPreset() {
        let stats = RecordingStatistics.zero
        #expect(stats.duration == 0)
        #expect(stats.fileSize == 0)
        #expect(stats.audioBuffersWritten == 0)
        #expect(stats.videoFramesWritten == 0)
        #expect(stats.filesCreated == 0)
        #expect(stats.currentFileURL == nil)
    }

    @Test("custom values are stored")
    func customValues() {
        let url = URL(filePath: "/tmp/test.mp4")
        let stats = RecordingStatistics(
            duration: 10.5,
            fileSize: 1024,
            audioBuffersWritten: 100,
            videoFramesWritten: 300,
            filesCreated: 1,
            currentFileURL: url
        )
        #expect(stats.duration == 10.5)
        #expect(stats.fileSize == 1024)
        #expect(stats.audioBuffersWritten == 100)
        #expect(stats.videoFramesWritten == 300)
        #expect(stats.filesCreated == 1)
        #expect(stats.currentFileURL == url)
    }

    @Test("Equatable conformance")
    func equatable() {
        #expect(RecordingStatistics.zero == RecordingStatistics.zero)
    }

    @Test("different values are not equal")
    func differentValuesNotEqual() {
        let a = RecordingStatistics.zero
        let b = RecordingStatistics(duration: 1.0)
        #expect(a != b)
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let stats: any Sendable = RecordingStatistics.zero
        _ = stats
    }
}
