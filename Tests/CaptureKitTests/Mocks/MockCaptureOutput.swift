// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockCaptureOutput: CaptureOutput {
    let outputID: String
    let displayName: String
    let outputType: CaptureOutputType

    private var _state: CaptureOutputState = .idle
    private(set) var prepareCallCount = 0
    private(set) var receiveAudioCallCount = 0
    private(set) var receiveVideoCallCount = 0
    private(set) var finalizeCallCount = 0

    private var _receivedAudioBuffers: [EncodedAudioBuffer] = []
    private var _receivedVideoFrames: [EncodedVideoFrame] = []

    var state: CaptureOutputState { _state }

    init(
        outputID: String = "mock-output",
        displayName: String = "Mock Output",
        outputType: CaptureOutputType = .callback
    ) {
        self.outputID = outputID
        self.displayName = displayName
        self.outputType = outputType
    }

    func prepare(audioFormat: AudioFormat?, videoFormat: VideoFormat?) async throws {
        prepareCallCount += 1
        _state = .ready
    }

    func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        receiveAudioCallCount += 1
        _receivedAudioBuffers.append(buffer)
        _state = .active
    }

    func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        receiveVideoCallCount += 1
        _receivedVideoFrames.append(frame)
        _state = .active
    }

    func finalize() async throws {
        finalizeCallCount += 1
        _state = .finalized
    }

    var receivedAudioBuffers: [EncodedAudioBuffer] { _receivedAudioBuffers }
    var receivedVideoFrames: [EncodedVideoFrame] { _receivedVideoFrames }
}
