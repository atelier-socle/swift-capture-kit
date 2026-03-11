// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Internal protocol abstracting video encoding (VideoToolbox VTCompressionSession).
///
/// Enables dependency injection for testing: real implementation uses
/// VTCompressionSession, tests inject a mock that tracks calls.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
protocol VideoEncoderProviding: Sendable {
    /// Configure the encoder with input and output parameters.
    ///
    /// - Parameters:
    ///   - width: The frame width in pixels.
    ///   - height: The frame height in pixels.
    ///   - codec: The target video codec.
    ///   - bitrate: The target bitrate in bits per second, if applicable.
    ///   - frameRate: The target frame rate.
    ///   - keyFrameInterval: The key frame interval in frames, if applicable.
    ///   - realTime: Whether to prioritize real-time encoding.
    ///   - profileLevel: The encoding profile/level string, if applicable.
    func configure(
        width: Int,
        height: Int,
        codec: VideoCodec,
        bitrate: Int?,
        frameRate: Double,
        keyFrameInterval: Int?,
        realTime: Bool,
        profileLevel: String?
    ) async throws

    /// Encode a raw video frame.
    ///
    /// - Parameters:
    ///   - data: The raw pixel data.
    ///   - width: The frame width in pixels.
    ///   - height: The frame height in pixels.
    ///   - timestamp: The presentation timestamp in seconds.
    ///   - isKeyFrame: Whether to force a key frame.
    /// - Returns: The encoded video data.
    func encode(
        data: Data,
        width: Int,
        height: Int,
        timestamp: TimeInterval,
        isKeyFrame: Bool
    ) async throws -> Data

    /// Force the next encoded frame to be a key frame.
    func forceKeyFrame() async throws

    /// Update the target bitrate dynamically.
    ///
    /// - Parameter bitrate: The new bitrate in bits per second.
    func updateBitrate(_ bitrate: Int) async throws

    /// Flush any remaining encoded data.
    ///
    /// - Returns: Any remaining encoded data, or nil.
    func flush() async throws -> Data?

    /// Reset the encoder to its initial state.
    func reset() async

    /// The format description from the most recent encode, if available.
    ///
    /// For VideoToolbox-backed encoders this is populated after the first
    /// successful ``encode(data:width:height:timestamp:isKeyFrame:)`` call
    /// and contains codec-specific parameter sets (e.g. SPS/PPS for H.264).
    var formatDescription: (any Sendable)? { get async }
}

/// Passthrough video encoder that returns data unchanged.
///
/// Used for Motion JPEG or when no compression is needed.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
struct PassthroughVideoEncoder: VideoEncoderProviding {
    func configure(
        width: Int, height: Int,
        codec: VideoCodec, bitrate: Int?,
        frameRate: Double, keyFrameInterval: Int?,
        realTime: Bool, profileLevel: String?
    ) async throws {}

    func encode(
        data: Data, width: Int, height: Int,
        timestamp: TimeInterval, isKeyFrame: Bool
    ) async throws -> Data {
        data
    }

    func forceKeyFrame() async throws {}
    func updateBitrate(_ bitrate: Int) async throws {}
    func flush() async throws -> Data? { nil }
    func reset() async {}
    var formatDescription: (any Sendable)? { nil }
}
