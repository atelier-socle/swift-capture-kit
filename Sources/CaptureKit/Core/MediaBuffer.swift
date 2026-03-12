// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Identifies an audio compression codec.
public enum AudioCodec: String, Sendable, CaseIterable {
    /// Advanced Audio Coding.
    case aac

    /// Apple Lossless Audio Codec.
    case alac

    /// Opus interactive audio codec.
    case opus

    /// Free Lossless Audio Codec.
    case flac

    /// Uncompressed pulse-code modulation.
    case pcm

    /// MPEG Audio Layer III.
    case mp3
}

/// Identifies a video compression codec.
public enum VideoCodec: String, Sendable, CaseIterable {
    /// H.264 / AVC.
    case h264

    /// H.265 / HEVC.
    case hevc

    /// Apple ProRes.
    case prores

    /// AOMedia Video 1.
    case av1

    /// Multiview HEVC for spatial video.
    case mvHevc

    /// JPEG image codec.
    case jpeg
}

/// A raw audio buffer containing uncompressed sample data.
public struct AudioBuffer: Sendable {
    /// The raw audio sample data.
    public let data: Data

    /// The format describing the audio samples.
    public let format: AudioFormat

    /// The presentation timestamp in seconds.
    public let timestamp: TimeInterval

    /// The duration of the audio in this buffer, in seconds.
    public let duration: TimeInterval

    /// A monotonically increasing sequence number.
    public let sequenceNumber: Int64

    /// Creates a raw audio buffer.
    ///
    /// - Parameters:
    ///   - data: The raw audio sample data.
    ///   - format: The audio format descriptor.
    ///   - timestamp: The presentation timestamp in seconds.
    ///   - duration: The duration of the audio in seconds.
    ///   - sequenceNumber: A monotonically increasing sequence number.
    public init(
        data: Data,
        format: AudioFormat,
        timestamp: TimeInterval,
        duration: TimeInterval,
        sequenceNumber: Int64
    ) {
        self.data = data
        self.format = format
        self.timestamp = timestamp
        self.duration = duration
        self.sequenceNumber = sequenceNumber
    }
}

/// A raw video frame containing uncompressed pixel data.
public struct VideoFrame: Sendable {
    /// The raw pixel data.
    public let data: Data

    /// The format describing the video frame.
    public let format: VideoFormat

    /// The presentation timestamp in seconds.
    public let timestamp: TimeInterval

    /// Whether this frame is a key frame (intra-coded).
    public let isKeyFrame: Bool

    /// A monotonically increasing sequence number.
    public let sequenceNumber: Int64

    /// Optional render metadata attached by the source.
    ///
    /// Sources may attach rendering hints for downstream consumers. For example,
    /// ``CinematicCameraSource`` includes `"fNumber"` so post-processing pipelines
    /// can apply depth-of-field blur matching the simulated aperture.
    public let metadata: [String: String]

    /// Creates a raw video frame.
    ///
    /// - Parameters:
    ///   - data: The raw pixel data.
    ///   - format: The video format descriptor.
    ///   - timestamp: The presentation timestamp in seconds.
    ///   - isKeyFrame: Whether this frame is a key frame.
    ///   - sequenceNumber: A monotonically increasing sequence number.
    ///   - metadata: Optional render metadata for downstream consumers.
    public init(
        data: Data,
        format: VideoFormat,
        timestamp: TimeInterval,
        isKeyFrame: Bool,
        sequenceNumber: Int64,
        metadata: [String: String] = [:]
    ) {
        self.data = data
        self.format = format
        self.timestamp = timestamp
        self.isKeyFrame = isKeyFrame
        self.sequenceNumber = sequenceNumber
        self.metadata = metadata
    }
}

/// An encoded audio buffer containing compressed audio data.
public struct EncodedAudioBuffer: Sendable {
    /// The compressed audio data.
    public let data: Data

    /// The codec used to encode the audio.
    public let codec: AudioCodec

    /// The presentation timestamp in seconds.
    public let timestamp: TimeInterval

    /// The duration of the encoded audio, in seconds.
    public let duration: TimeInterval

    /// A monotonically increasing sequence number.
    public let sequenceNumber: Int64

    /// Sizes of individual access units within ``data``.
    ///
    /// When non-nil, ``data`` contains `packetSizes.count` concatenated
    /// codec packets whose sizes sum to `data.count`.
    /// This is essential for ADTS framing in HTTP streaming (Icecast, HLS).
    ///
    /// Only VBR codecs (AAC, Opus) provide packet sizes.  CBR or
    /// passthrough encoders leave this `nil`.
    public let packetSizes: [Int]?

    /// Creates an encoded audio buffer.
    ///
    /// - Parameters:
    ///   - data: The compressed audio data.
    ///   - codec: The audio codec used for encoding.
    ///   - timestamp: The presentation timestamp in seconds.
    ///   - duration: The duration of the encoded audio in seconds.
    ///   - sequenceNumber: A monotonically increasing sequence number.
    ///   - packetSizes: Optional per-packet sizes within `data`.
    public init(
        data: Data,
        codec: AudioCodec,
        timestamp: TimeInterval,
        duration: TimeInterval,
        sequenceNumber: Int64,
        packetSizes: [Int]? = nil
    ) {
        self.data = data
        self.codec = codec
        self.timestamp = timestamp
        self.duration = duration
        self.sequenceNumber = sequenceNumber
        self.packetSizes = packetSizes
    }

    /// Returns a copy with the timestamp replaced.
    public func withTimestamp(_ newTimestamp: TimeInterval) -> EncodedAudioBuffer {
        EncodedAudioBuffer(
            data: data,
            codec: codec,
            timestamp: newTimestamp,
            duration: duration,
            sequenceNumber: sequenceNumber,
            packetSizes: packetSizes
        )
    }
}

/// An encoded video frame containing compressed video data.
public struct EncodedVideoFrame: Sendable {
    /// The compressed video data.
    public let data: Data

    /// The codec used to encode the video.
    public let codec: VideoCodec

    /// The presentation timestamp in seconds.
    public let timestamp: TimeInterval

    /// Whether this frame is a key frame (intra-coded).
    public let isKeyFrame: Bool

    /// A monotonically increasing sequence number.
    public let sequenceNumber: Int64

    /// Creates an encoded video frame.
    ///
    /// - Parameters:
    ///   - data: The compressed video data.
    ///   - codec: The video codec used for encoding.
    ///   - timestamp: The presentation timestamp in seconds.
    ///   - isKeyFrame: Whether this frame is a key frame.
    ///   - sequenceNumber: A monotonically increasing sequence number.
    public init(
        data: Data,
        codec: VideoCodec,
        timestamp: TimeInterval,
        isKeyFrame: Bool,
        sequenceNumber: Int64
    ) {
        self.data = data
        self.codec = codec
        self.timestamp = timestamp
        self.isKeyFrame = isKeyFrame
        self.sequenceNumber = sequenceNumber
    }

    /// Returns a copy with the timestamp replaced.
    public func withTimestamp(_ newTimestamp: TimeInterval) -> EncodedVideoFrame {
        EncodedVideoFrame(
            data: data,
            codec: codec,
            timestamp: newTimestamp,
            isKeyFrame: isKeyFrame,
            sequenceNumber: sequenceNumber
        )
    }
}
