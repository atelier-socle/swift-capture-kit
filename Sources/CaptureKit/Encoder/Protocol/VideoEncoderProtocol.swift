// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Configuration parameters for a video encoder.
public struct VideoEncoderConfiguration: Sendable, Equatable {
    /// The target bitrate in bits per second.
    public var bitrate: Int

    /// The target resolution for encoded video.
    public var resolution: VideoResolution

    /// The target frame rate for encoded video.
    public var frameRate: FrameRate

    /// The interval between key frames in number of frames.
    public var keyFrameInterval: Int

    /// Whether the encoder should prioritize real-time performance.
    public var realTime: Bool

    /// Creates a new video encoder configuration.
    ///
    /// - Parameters:
    ///   - bitrate: The target bitrate in bits per second.
    ///   - resolution: The target resolution.
    ///   - frameRate: The target frame rate.
    ///   - keyFrameInterval: The key frame interval in frames.
    ///   - realTime: Whether to prioritize real-time encoding.
    public init(
        bitrate: Int,
        resolution: VideoResolution,
        frameRate: FrameRate,
        keyFrameInterval: Int,
        realTime: Bool
    ) {
        self.bitrate = bitrate
        self.resolution = resolution
        self.frameRate = frameRate
        self.keyFrameInterval = keyFrameInterval
        self.realTime = realTime
    }
}

/// Protocol for video encoders that compress raw video frames.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public protocol VideoEncoderProtocol: Sendable {
    /// The video codec used by this encoder.
    var codec: VideoCodec { get }

    /// The resolutions supported by this encoder.
    var supportedResolutions: [VideoResolution] { get }

    /// The frame rates supported by this encoder.
    var supportedFrameRates: [FrameRate] { get }

    /// The range of bitrates supported by this encoder in bits per second.
    var supportedBitRates: ClosedRange<Int> { get }

    /// The encoding profiles supported by this encoder.
    var supportedProfiles: [String] { get }

    /// Whether this encoder uses hardware acceleration.
    var isHardwareAccelerated: Bool { get }

    /// Configures the encoder with the given configuration.
    ///
    /// - Parameter config: The desired encoder configuration.
    func configure(_ config: VideoEncoderConfiguration) async throws

    /// Encodes a raw video frame into an encoded video frame.
    ///
    /// - Parameter frame: The raw video frame to encode.
    /// - Returns: The encoded video frame.
    func encode(_ frame: VideoFrame) async throws -> EncodedVideoFrame

    /// Forces the encoder to produce a key frame on the next encode call.
    func forceKeyFrame() async throws

    /// Updates the target bitrate dynamically during encoding.
    ///
    /// - Parameter bitrate: The new target bitrate in bits per second.
    func updateBitrate(_ bitrate: Int) async throws

    /// Flushes any buffered data and returns remaining encoded frames.
    ///
    /// - Returns: An array of any remaining encoded video frames.
    func flush() async throws -> [EncodedVideoFrame]

    /// Resets the encoder to its initial state.
    func reset() async
}
