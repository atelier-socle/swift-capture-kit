// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CaptureOutput", .timeLimit(.minutes(1)))
struct CaptureOutputTests {

    @Test("MockCaptureOutput conforms to CaptureOutput protocol")
    func mockConformsToProtocol() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let output = MockCaptureOutput()
        #expect(output.outputID == "mock-output")
        #expect(output.displayName == "Mock Output")
        #expect(output.outputType == .callback)

        let initialState = await output.state
        #expect(initialState == .idle)

        let audioFormat = AudioFormat(sampleRate: .rate48000, channelCount: 2)
        let videoFormat = VideoFormat(resolution: .p1080, frameRate: .fps30)
        try await output.prepare(audioFormat: audioFormat, videoFormat: videoFormat)

        let prepareCount = await output.prepareCallCount
        #expect(prepareCount == 1)

        let readyState = await output.state
        #expect(readyState == .ready)

        let encodedAudio = EncodedAudioBuffer(
            data: Data([0x01]),
            codec: .aac,
            timestamp: 0.0,
            duration: 0.02,
            sequenceNumber: 1
        )
        try await output.receiveAudio(encodedAudio)
        let audioCount = await output.receiveAudioCallCount
        #expect(audioCount == 1)

        let encodedVideo = EncodedVideoFrame(
            data: Data([0x02]),
            codec: .h264,
            timestamp: 0.0,
            isKeyFrame: true,
            sequenceNumber: 1
        )
        try await output.receiveVideo(encodedVideo)
        let videoCount = await output.receiveVideoCallCount
        #expect(videoCount == 1)

        try await output.finalize()
        let finalizeCount = await output.finalizeCallCount
        #expect(finalizeCount == 1)

        let finalState = await output.state
        #expect(finalState == .finalized)
    }

    @Test("CaptureOutputType CaseIterable count is nine")
    func outputTypeCaseCount() {
        #expect(CaptureOutputType.allCases.count == 9)
    }

    @Test("CaptureOutputState CaseIterable count is seven")
    func outputStateCaseCount() {
        #expect(CaptureOutputState.allCases.count == 7)
    }

    @Test("CaptureOutputType rawValues match expected strings")
    func outputTypeRawValues() {
        #expect(CaptureOutputType.file.rawValue == "file")
        #expect(CaptureOutputType.streaming.rawValue == "streaming")
        #expect(CaptureOutputType.callback.rawValue == "callback")
        #expect(CaptureOutputType.null.rawValue == "null")
        #expect(CaptureOutputType.tee.rawValue == "tee")
    }
}
