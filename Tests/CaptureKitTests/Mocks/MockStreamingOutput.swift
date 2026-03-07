// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

/// Mock streaming output for testing transport quality feedback.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockStreamingOutput: StreamingOutput {
    // MARK: - CaptureOutput Protocol

    /// A unique identifier for this output.
    let outputID: String

    /// A human-readable display name for this output.
    let displayName: String = "Mock Streaming Output"

    /// The type of this output destination.
    let outputType: CaptureOutputType = .streaming

    /// The current lifecycle state of this output.
    private var _state: CaptureOutputState = .idle

    /// The current lifecycle state.
    var state: CaptureOutputState { _state }

    // MARK: - StreamingOutput Protocol

    /// The current connection state of the streaming transport.
    private var _connectionState: StreamingConnectionState = .disconnected

    /// The current connection state.
    var connectionState: StreamingConnectionState { _connectionState }

    /// The current transport quality metrics.
    var transportQuality: StreamingTransportQuality?

    // MARK: - Tracking

    /// Number of times `prepare()` was called.
    private(set) var prepareCallCount = 0

    /// Number of times `receiveAudio()` was called.
    private(set) var receiveAudioCallCount = 0

    /// Number of times `receiveVideo()` was called.
    private(set) var receiveVideoCallCount = 0

    /// Number of times `deliverAudio()` was called.
    private(set) var audioDeliveryCount = 0

    /// Number of times `deliverVideo()` was called.
    private(set) var videoDeliveryCount = 0

    /// Number of times `finalize()` was called.
    private(set) var finalizeCallCount = 0

    /// Simulated transport quality for testing.
    var simulatedQuality: StreamingTransportQuality?

    // MARK: - Initialization

    /// Creates a new mock streaming output.
    init(
        outputID: String = "mock-streaming-\(UUID().uuidString.prefix(8))"
    ) {
        self.outputID = outputID
    }

    // MARK: - CaptureOutput Methods

    /// Prepares the output for receiving media.
    func prepare(
        audioFormat: AudioFormat?, videoFormat: VideoFormat?
    ) async throws {
        prepareCallCount += 1
        _state = .ready
        _connectionState = .connected
    }

    /// Receives an encoded audio buffer.
    func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        receiveAudioCallCount += 1
        _state = .active
    }

    /// Receives an encoded video frame.
    func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        receiveVideoCallCount += 1
        _state = .active
    }

    /// Finalizes the output.
    func finalize() async throws {
        finalizeCallCount += 1
        _state = .finalized
        _connectionState = .disconnected
    }

    // MARK: - StreamingOutput Methods

    /// Delivers an encoded audio buffer to the streaming destination.
    func deliverAudio(_ buffer: EncodedAudioBuffer) async throws {
        audioDeliveryCount += 1
    }

    /// Delivers an encoded video frame to the streaming destination.
    func deliverVideo(_ buffer: EncodedVideoFrame) async throws {
        videoDeliveryCount += 1
    }

    // MARK: - Test Helpers

    /// Sets the simulated connection state.
    func setConnectionState(_ state: StreamingConnectionState) {
        _connectionState = state
    }

    /// Sets the simulated transport quality.
    func setTransportQuality(_ quality: StreamingTransportQuality?) {
        transportQuality = quality
    }
}
