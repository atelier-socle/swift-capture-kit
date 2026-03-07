// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Captures from USB, Thunderbolt, or Continuity Camera devices.
@available(macOS 14.0, iOS 17.0, *)
public actor ExternalCameraSource: VideoSource {
    /// The unique identifier for this external camera source.
    public let sourceID: String

    /// The display name derived from the device name.
    public let displayName: String

    /// The type of this video source.
    public let sourceType: VideoSourceType = .externalCamera

    /// The availability of this source, requiring camera permission.
    public nonisolated var availability: SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: true,
            isAvailableOnCurrentDevice: true,
            requiredPermissions: [.camera],
            minimumOSVersion: nil,
            notes: "Requires external camera connected via USB, Thunderbolt, or Continuity Camera"
        )
    }

    /// Whether this source is currently capturing video.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// Selected external device.
    public var selectedDevice: VideoDeviceInfo

    /// Continuity Camera features (nil if not a Continuity Camera).
    public var continuityCameraFeatures: ContinuityCameraFeatures?

    /// The current configuration.
    private var configuration: VideoSourceConfiguration

    /// The video formats supported by this source.
    public var supportedFormats: [VideoFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new external camera source.
    ///
    /// - Parameter device: The video device info for the external camera.
    public init(device: VideoDeviceInfo) {
        self.sourceID = "external-\(UUID().uuidString.prefix(8))"
        self.displayName = device.name
        self.selectedDevice = device
        self.continuityCameraFeatures = nil
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

    /// Starts capturing video and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of captured video frames.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    public func startCapture() async throws -> AsyncStream<VideoFrame> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        isCapturing = true
        self.activeFormat = makeFormat(from: configuration)

        return AsyncStream { continuation in
            continuation.finish()
        }
    }

    /// Stops the current video capture.
    public func stopCapture() async {
        isCapturing = false
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
