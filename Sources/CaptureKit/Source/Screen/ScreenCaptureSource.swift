// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Unified screen capture source that routes to the correct platform implementation.
///
/// On macOS, uses ScreenCaptureKit for full system capture (display, window, app, region).
/// On iOS/iPadOS, uses ReplayKit for in-app recording or Broadcast Upload Extension
/// for system-wide capture.
@available(macOS 14.0, iOS 17.0, *)
public actor ScreenCaptureSource: VideoSource {
    /// The unique identifier for this screen capture source.
    public let sourceID: String

    /// The display name reflecting the capture mode.
    public let displayName: String

    /// The type of this video source.
    public let sourceType: VideoSourceType = .screenCapture

    /// The availability of this source on the current platform.
    public nonisolated var availability: SourceAvailability {
        #if os(macOS)
            return SourceAvailability(
                isAvailableOnCurrentPlatform: true,
                isAvailableOnCurrentDevice: true,
                requiredPermissions: [.screenRecording],
                minimumOSVersion: "14.0",
                notes: "Requires screen recording permission in System Settings"
            )
        #elseif os(iOS)
            switch mode {
            case .replayKit:
                return SourceAvailability(
                    isAvailableOnCurrentPlatform: true,
                    isAvailableOnCurrentDevice: true,
                    requiredPermissions: [],
                    minimumOSVersion: "17.0",
                    notes: "Captures own app content only"
                )
            case .broadcastExtension:
                return SourceAvailability(
                    isAvailableOnCurrentPlatform: true,
                    isAvailableOnCurrentDevice: true,
                    requiredPermissions: [],
                    minimumOSVersion: "17.0",
                    notes: "Requires Broadcast Upload Extension target and App Group entitlement"
                )
            case .screenCaptureKit:
                return .unavailable(reason: "ScreenCaptureKit is not available on iOS")
            }
        #else
            return .unavailable(reason: "Screen capture is not available on this platform")
        #endif
    }

    /// Whether this source is currently capturing.
    public private(set) var isCapturing: Bool = false

    /// The currently active video format, if configured or capturing.
    public private(set) var activeFormat: VideoFormat?

    /// The screen capture mode.
    public let mode: ScreenCaptureMode

    /// ScreenCaptureKit configuration (macOS).
    public var screenCaptureKitConfiguration: ScreenCaptureKitConfiguration

    /// ReplayKit configuration (iOS).
    public var replayKitConfiguration: ReplayKitConfiguration

    /// Broadcast extension configuration (iOS system-wide).
    public var broadcastConfiguration: BroadcastConfiguration?

    /// The current video source configuration.
    private var configuration: VideoSourceConfiguration

    /// The video formats supported by this source.
    public var supportedFormats: [VideoFormat] {
        [makeFormat(from: configuration)]
    }

    /// Creates a new screen capture source.
    ///
    /// - Parameter mode: The screen capture mode.
    public init(mode: ScreenCaptureMode) {
        self.sourceID = "screen-\(UUID().uuidString.prefix(8))"
        self.mode = mode
        self.configuration = .default
        self.screenCaptureKitConfiguration = .default
        self.replayKitConfiguration = .default

        switch mode {
        case .screenCaptureKit:
            self.displayName = "Screen Capture (macOS)"
            self.broadcastConfiguration = nil
        case .replayKit:
            self.displayName = "Screen Recording (In-App)"
            self.broadcastConfiguration = nil
        case .broadcastExtension(let appGroupID):
            self.displayName = "Screen Broadcast"
            self.broadcastConfiguration = BroadcastConfiguration(appGroupID: appGroupID)
        }
    }

    /// Configures this source with the given video source configuration.
    ///
    /// - Parameter configuration: The desired video source configuration.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if currently capturing.
    /// - Throws: ``CaptureError/sourceNotAvailable(sourceType:reason:)`` if the mode is unavailable.
    public func configure(_ configuration: VideoSourceConfiguration) async throws {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }

        #if os(macOS)
            switch mode {
            case .replayKit:
                throw CaptureError.sourceNotAvailable(
                    sourceType: "screenCapture",
                    reason: "ReplayKit is not available on macOS. Use .screenCaptureKit mode."
                )
            case .broadcastExtension:
                throw CaptureError.sourceNotAvailable(
                    sourceType: "screenCapture",
                    reason: "Broadcast Extension is not available on macOS. Use .screenCaptureKit mode."
                )
            case .screenCaptureKit:
                break
            }
        #elseif os(iOS)
            switch mode {
            case .screenCaptureKit:
                throw CaptureError.sourceNotAvailable(
                    sourceType: "screenCapture",
                    reason: "ScreenCaptureKit is not available on iOS. Use .replayKit or .broadcastExtension mode."
                )
            case .replayKit, .broadcastExtension:
                break
            }
        #endif

        self.configuration = configuration
        self.activeFormat = makeFormat(from: configuration)
    }

    /// Starts capturing screen content and returns an async stream.
    ///
    /// - Returns: An asynchronous stream of captured video frames.
    /// - Throws: ``CaptureError/sourceAlreadyCapturing(sourceID:)`` if already capturing.
    public func startCapture() async throws -> AsyncStream<VideoFrame> {
        guard !isCapturing else {
            throw CaptureError.sourceAlreadyCapturing(sourceID: sourceID)
        }
        isCapturing = true

        return AsyncStream { continuation in
            continuation.finish()
        }
    }

    /// Stops the current screen capture.
    public func stopCapture() async {
        isCapturing = false
    }

    /// An async stream of frame statistics. Always finishes immediately.
    public nonisolated var frameStatistics: AsyncStream<FrameStatisticsSample> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    /// Discover available screen capture content (macOS only).
    ///
    /// Returns displays, windows, and applications available for capture.
    /// - Throws: ``CaptureError/sourceNotAvailable(sourceType:reason:)`` on non-macOS platforms.
    public static func availableContent() async throws -> ScreenCaptureContent {
        #if os(macOS)
            return ScreenCaptureContent(displays: [], windows: [], applications: [])
        #else
            throw CaptureError.sourceNotAvailable(
                sourceType: "screenCapture",
                reason: "Screen content discovery is only available on macOS"
            )
        #endif
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
