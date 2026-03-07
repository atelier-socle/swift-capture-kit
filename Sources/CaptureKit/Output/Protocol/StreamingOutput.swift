// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Protocol for streaming output destinations that deliver encoded media over a network.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public protocol StreamingOutput: CaptureOutput {
    /// Delivers an encoded audio buffer to the streaming destination.
    ///
    /// - Parameter buffer: The encoded audio buffer to deliver.
    func deliverAudio(_ buffer: EncodedAudioBuffer) async throws

    /// Delivers an encoded video frame to the streaming destination.
    ///
    /// - Parameter buffer: The encoded video frame to deliver.
    func deliverVideo(_ buffer: EncodedVideoFrame) async throws

    /// The current connection state of the streaming transport.
    var connectionState: StreamingConnectionState { get async }

    /// The current transport quality metrics, if available.
    var transportQuality: StreamingTransportQuality? { get async }
}
