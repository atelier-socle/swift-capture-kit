// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// A media packet carrying either encoded video or audio data through the
/// streaming pipeline's mux channel.
public enum MediaPacket: Sendable {

    /// An encoded video frame ready for transport.
    case video(EncodedVideoFrame)

    /// An encoded audio buffer ready for transport.
    case audio(EncodedAudioBuffer)

    /// Presentation timestamp in seconds, forwarded from the underlying
    /// encoded frame or buffer.
    public var timestamp: TimeInterval {
        switch self {
        case .video(let frame): frame.timestamp
        case .audio(let buffer): buffer.timestamp
        }
    }

    /// Returns a copy of this packet with its timestamp replaced.
    public func withTimestamp(_ newTimestamp: TimeInterval) -> MediaPacket {
        switch self {
        case .video(let frame):
            .video(frame.withTimestamp(newTimestamp))
        case .audio(let buffer):
            .audio(buffer.withTimestamp(newTimestamp))
        }
    }
}
