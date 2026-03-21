// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CaptureSessionStatistics", .timeLimit(.minutes(1)))
struct CaptureSessionStatisticsTests {

    @Test("zero has all zero values")
    func zeroStatistics() {
        let stats = CaptureSessionStatistics.zero
        #expect(stats.uptime == 0)
        #expect(stats.audioBuffersProcessed == 0)
        #expect(stats.videoFramesProcessed == 0)
        #expect(stats.videoFramesDropped == 0)
        #expect(stats.audioBytesEncoded == 0)
        #expect(stats.videoBytesEncoded == 0)
        #expect(stats.currentAudioBitrate == 0)
        #expect(stats.currentVideoBitrate == 0)
        #expect(stats.currentFrameRate == 0)
        #expect(stats.cpuUsage == 0)
        #expect(stats.memoryUsage == 0)
    }

    @Test("Init with values stores all properties")
    func initWithValues() {
        let stats = CaptureSessionStatistics(
            uptime: 120.5,
            audioBuffersProcessed: 1000,
            videoFramesProcessed: 3600,
            videoFramesDropped: 5,
            audioBytesEncoded: 500_000,
            videoBytesEncoded: 10_000_000,
            currentAudioBitrate: 128_000,
            currentVideoBitrate: 5_000_000,
            currentFrameRate: 29.97,
            cpuUsage: 42.5,
            memoryUsage: 256_000_000
        )
        #expect(stats.uptime == 120.5)
        #expect(stats.audioBuffersProcessed == 1000)
        #expect(stats.videoFramesProcessed == 3600)
        #expect(stats.videoFramesDropped == 5)
        #expect(stats.audioBytesEncoded == 500_000)
        #expect(stats.videoBytesEncoded == 10_000_000)
        #expect(stats.currentAudioBitrate == 128_000)
        #expect(stats.currentVideoBitrate == 5_000_000)
        #expect(stats.currentFrameRate == 29.97)
        #expect(stats.cpuUsage == 42.5)
        #expect(stats.memoryUsage == 256_000_000)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = CaptureSessionStatistics.zero
        let b = CaptureSessionStatistics.zero
        #expect(a == b)

        let c = CaptureSessionStatistics(
            uptime: 1, audioBuffersProcessed: 0, videoFramesProcessed: 0,
            videoFramesDropped: 0, audioBytesEncoded: 0, videoBytesEncoded: 0,
            currentAudioBitrate: 0, currentVideoBitrate: 0, currentFrameRate: 0,
            cpuUsage: 0, memoryUsage: 0
        )
        #expect(a != c)
    }

    @Test("Sendable conformance")
    func sendableConformance() {
        let stats: any Sendable = CaptureSessionStatistics.zero
        #expect(stats is CaptureSessionStatistics)
    }
}
