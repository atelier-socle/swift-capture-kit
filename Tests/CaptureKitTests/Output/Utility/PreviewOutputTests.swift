// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("PreviewOutput", .timeLimit(.minutes(1)))
struct PreviewOutputTests {

    @Test("has preview output type")
    func hasPreviewOutputType() {
        let output = PreviewOutput()
        #expect(output.outputType == .preview)
    }

    @Test("starts with no latest frame")
    func startsWithNoLatestFrame() async {
        let output = PreviewOutput()
        #expect(await output.latestFrame == nil)
    }

    @Test("receiveVideo stores latest frame")
    func receiveVideoStoresLatestFrame() async throws {
        let output = PreviewOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([1, 2, 3]), codec: .h264,
            timestamp: 0.5, isKeyFrame: true, sequenceNumber: 1)
        try await output.receiveVideo(frame)
        let latest = await output.latestFrame
        #expect(latest?.timestamp == 0.5)
        #expect(latest?.sequenceNumber == 1)
    }

    @Test("receiveAudio is no-op")
    func receiveAudioIsNoOp() async throws {
        let output = PreviewOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let buffer = EncodedAudioBuffer(
            data: Data([0]), codec: .aac,
            timestamp: 0, duration: 0.1, sequenceNumber: 0)
        try await output.receiveAudio(buffer)
        #expect(await output.framesReceived == 0)
    }

    @Test("framesReceived increments")
    func framesReceivedIncrements() async throws {
        let output = PreviewOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        try await output.receiveVideo(frame)
        #expect(await output.framesReceived == 2)
    }

    @Test("finalize clears latest frame")
    func finalizeClearsLatestFrame() async throws {
        let output = PreviewOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame = EncodedVideoFrame(
            data: Data([0]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        try await output.finalize()
        #expect(await output.latestFrame == nil)
        #expect(await output.state == .finalized)
    }

    @Test("dropFramesWhenBehind default is true")
    func dropFramesWhenBehindDefault() async {
        let output = PreviewOutput()
        #expect(await output.dropFramesWhenBehind == true)
    }

    @Test("dropFramesWhenBehind can be set to false")
    func dropFramesWhenBehindFalse() async {
        let output = PreviewOutput(dropFramesWhenBehind: false)
        #expect(await output.dropFramesWhenBehind == false)
    }

    @Test("latest frame updates on each receive")
    func latestFrameUpdatesOnEachReceive() async throws {
        let output = PreviewOutput()
        try await output.prepare(audioFormat: nil, videoFormat: nil)
        let frame1 = EncodedVideoFrame(
            data: Data([1]), codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 1)
        let frame2 = EncodedVideoFrame(
            data: Data([2]), codec: .h264,
            timestamp: 1, isKeyFrame: false, sequenceNumber: 2)
        try await output.receiveVideo(frame1)
        try await output.receiveVideo(frame2)
        let latest = await output.latestFrame
        #expect(latest?.sequenceNumber == 2)
    }

    @Test("generates unique output ID")
    func uniqueOutputID() async {
        let a = PreviewOutput()
        let id = await a.outputID
        #expect(id.hasPrefix("preview-"))
    }

    @Test("prepare with video format sets active state")
    func prepareWithVideoFormatSetsActiveState() async throws {
        let output = PreviewOutput()
        let format = VideoFormat(
            resolution: .p720,
            frameRate: .fps30,
            pixelFormat: .bgra,
            colorSpace: .srgb,
            dynamicRange: .sdr
        )
        try await output.prepare(audioFormat: nil, videoFormat: format)
        #expect(await output.state == .active)
    }

    @Test("receiveVideo with BGRA data and video format increments frames")
    func receiveVideoWithBGRAData() async throws {
        let output = PreviewOutput()
        let format = VideoFormat(
            resolution: .custom(width: 4, height: 4),
            frameRate: .fps30,
            pixelFormat: .bgra,
            colorSpace: .srgb,
            dynamicRange: .sdr
        )
        try await output.prepare(audioFormat: nil, videoFormat: format)
        // 4x4 BGRA = 64 bytes
        let data = Data(repeating: 0xFF, count: 4 * 4 * 4)
        let frame = EncodedVideoFrame(
            data: data, codec: .h264,
            timestamp: 0, isKeyFrame: true, sequenceNumber: 0)
        try await output.receiveVideo(frame)
        #expect(await output.framesReceived == 1)
    }
}
