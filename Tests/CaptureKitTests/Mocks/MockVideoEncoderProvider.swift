// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

/// Mock video encoder provider for testing without VideoToolbox.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockVideoEncoderProvider: VideoEncoderProviding {
    /// Number of configure() calls.
    var configureCallCount = 0

    /// Number of encode() calls.
    var encodeCallCount = 0

    /// Number of reset() calls.
    var resetCallCount = 0

    /// Number of forceKeyFrame() calls.
    var forceKeyFrameCallCount = 0

    /// Number of updateBitrate() calls.
    var updateBitrateCallCount = 0

    /// The last codec passed to configure().
    var lastCodec: VideoCodec?

    /// The last bitrate passed to configure() or updateBitrate().
    var lastBitrate: Int?

    /// Whether configure() should throw.
    var shouldThrowOnConfigure = false

    /// Whether encode() should throw.
    var shouldThrowOnEncode = false

    func configure(
        width: Int, height: Int,
        codec: VideoCodec, bitrate: Int?,
        frameRate: Double, keyFrameInterval: Int?,
        realTime: Bool, profileLevel: String?
    ) async throws {
        configureCallCount += 1
        lastCodec = codec
        lastBitrate = bitrate
        if shouldThrowOnConfigure {
            throw CaptureError.encoderConfigurationFailed(
                codec: codec.rawValue,
                reason: "Mock configure error"
            )
        }
    }

    func encode(
        data: Data, width: Int, height: Int,
        timestamp: TimeInterval, isKeyFrame: Bool
    ) async throws -> Data {
        encodeCallCount += 1
        if shouldThrowOnEncode {
            throw CaptureError.encodingFailed(
                codec: "mock",
                reason: "Mock encode error"
            )
        }
        return data
    }

    func forceKeyFrame() async throws {
        forceKeyFrameCallCount += 1
    }

    func updateBitrate(_ bitrate: Int) async throws {
        updateBitrateCallCount += 1
        lastBitrate = bitrate
    }

    func flush() async throws -> Data? { nil }

    func reset() async {
        resetCallCount += 1
    }

    var formatDescription: (any Sendable)? { nil }
    var lastFrameIsKeyFrame: Bool { true }
}
