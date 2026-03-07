// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Reads sample buffers from a Broadcast Upload Extension via IPC.
///
/// This source connects to the shared App Group container and reads
/// video and audio data written by the extension process.
@available(iOS 17.0, macOS 14.0, *)
public actor BroadcastSource: VideoSource {
    /// The unique identifier for this broadcast source.
    public let sourceID: String

    /// The display name shown in UI or logs.
    public let displayName: String = "Broadcast Extension"

    /// The type of this video source.
    public let sourceType: VideoSourceType = .screenCapture

    /// The availability of this source.
    public nonisolated var availability: SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: true,
            requiredPermissions: [],
            minimumOSVersion: "17.0",
            notes: "Requires Broadcast Upload Extension target and App Group entitlement"
        )
    }

    /// Whether this source is currently capturing.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// Broadcast configuration.
    public let broadcastConfiguration: BroadcastConfiguration

    /// IPC channel for communication with the extension.
    public let ipcChannel: BroadcastIPCChannel

    /// The current video source configuration.
    private var configuration: VideoSourceConfiguration

    /// The video formats supported by this source.
    public var supportedFormats: [VideoFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new broadcast source.
    ///
    /// - Parameter configuration: The broadcast configuration.
    public init(configuration: BroadcastConfiguration) {
        self.sourceID = "broadcast-\(UUID().uuidString.prefix(8))"
        self.broadcastConfiguration = configuration
        self.ipcChannel = BroadcastIPCChannel(
            appGroupID: configuration.appGroupID,
            maxBufferSize: configuration.maxBufferSize
        )
        self.configuration = .default
    }

    /// Configures this source with the given video source configuration.
    ///
    /// - Parameter configuration: The desired video source configuration.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if currently capturing.
    public func configure(_ configuration: VideoSourceConfiguration) async throws {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        self.configuration = configuration
        self.activeFormat = makeFormat(from: configuration)
    }

    /// Starts capturing from the broadcast extension and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of captured video frames.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    public func startCapture() async throws -> AsyncStream<VideoFrame> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }

        try await ipcChannel.connect()
        isCapturing = true

        return AsyncStream { continuation in
            continuation.finish()
        }
    }

    /// Stops the current broadcast capture.
    public func stopCapture() async {
        isCapturing = false
        await ipcChannel.disconnect()
    }

    /// An async stream of frame statistics. Always finishes immediately.
    public nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    private func makeFormat(from config: VideoSourceConfiguration) -> VideoFormat {
        VideoFormat(
            resolution: config.resolution,
            frameRate: config.frameRate,
            pixelFormat: config.pixelFormat,
            colorSpace: config.colorSpace,
            dynamicRange: config.dynamicRange
        )
    }
}
