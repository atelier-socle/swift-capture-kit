// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Represents the type of a video capture source.
public enum VideoSourceType: String, Sendable, CaseIterable {
    /// A built-in camera on the device.
    case builtInCamera

    /// An externally connected camera.
    case externalCamera

    /// Screen capture of the display.
    case screenCapture

    /// A spatial camera for capturing 3D video.
    case spatialCamera

    /// A cinematic camera with depth-of-field effects.
    case cinematicCamera

    /// A multi-camera setup combining multiple camera inputs.
    case multiCamera

    /// A video file used as a capture source.
    case file

    /// A programmatic video signal generator.
    case generator
}

/// Represents video stabilization modes.
public enum VideoStabilization: String, Sendable, CaseIterable {
    /// No stabilization applied.
    case off

    /// Standard electronic stabilization.
    case standard

    /// Cinematic stabilization with smooth motion.
    case cinematic

    /// Extended cinematic stabilization with additional smoothing.
    case cinematicExtended

    /// Automatic stabilization selection based on conditions.
    case auto

    /// Prefer cinematic stabilization when available.
    case preferCinematic
}

/// Represents camera focus modes.
public enum FocusMode: String, Sendable, CaseIterable {
    /// Focus is locked at the current position.
    case locked

    /// Single auto-focus pass.
    case autoFocus

    /// Continuous auto-focus tracking.
    case continuousAutoFocus

    /// Manual focus control.
    case manualFocus
}

/// Represents camera exposure modes.
public enum ExposureMode: String, Sendable, CaseIterable {
    /// Exposure is locked at the current value.
    case locked

    /// Single auto-exposure pass.
    case autoExpose

    /// Continuous auto-exposure adjustment.
    case continuousAutoExposure

    /// Manual exposure control.
    case manualExposure
}

/// Represents white balance modes for a camera.
public enum WhiteBalanceMode: Sendable, Equatable, Hashable {
    /// White balance is locked at the current value.
    case locked

    /// Single auto white balance pass.
    case autoWhiteBalance

    /// Continuous auto white balance adjustment.
    case continuousAutoWhiteBalance

    /// Manual white balance control.
    case manualWhiteBalance

    /// Manual white balance set to a specific color temperature.
    case temperature(kelvin: Int)
}

/// Configuration for a video capture source.
public struct VideoSourceConfiguration: Sendable, Equatable {
    /// The desired capture resolution.
    public var resolution: VideoResolution

    /// The desired capture frame rate.
    public var frameRate: FrameRate

    /// The desired pixel format for captured frames.
    public var pixelFormat: PixelFormat

    /// The desired color space.
    public var colorSpace: ColorSpace

    /// The desired dynamic range mode.
    public var dynamicRange: DynamicRange

    /// The desired video stabilization mode.
    public var stabilization: VideoStabilization

    /// The desired focus mode.
    public var focusMode: FocusMode

    /// The desired exposure mode.
    public var exposureMode: ExposureMode

    /// The desired white balance mode.
    public var whiteBalanceMode: WhiteBalanceMode

    /// Default configuration: 1080p, 30 fps, NV12, BT.709, SDR.
    public static let `default` = VideoSourceConfiguration(
        resolution: .p1080,
        frameRate: .fps30,
        pixelFormat: .nv12,
        colorSpace: .bt709,
        dynamicRange: .sdr,
        stabilization: .off,
        focusMode: .continuousAutoFocus,
        exposureMode: .continuousAutoExposure,
        whiteBalanceMode: .continuousAutoWhiteBalance
    )

    /// Broadcast 720p configuration: 720p, 30 fps, standard stabilization.
    public static let broadcast720p = VideoSourceConfiguration(
        resolution: .p720,
        frameRate: .fps30,
        pixelFormat: .nv12,
        colorSpace: .bt709,
        dynamicRange: .sdr,
        stabilization: .standard,
        focusMode: .continuousAutoFocus,
        exposureMode: .continuousAutoExposure,
        whiteBalanceMode: .continuousAutoWhiteBalance
    )

    /// Broadcast 1080p60 configuration: 1080p, 60 fps, standard stabilization.
    public static let broadcast1080p60 = VideoSourceConfiguration(
        resolution: .p1080,
        frameRate: .fps60,
        pixelFormat: .nv12,
        colorSpace: .bt709,
        dynamicRange: .sdr,
        stabilization: .standard,
        focusMode: .continuousAutoFocus,
        exposureMode: .continuousAutoExposure,
        whiteBalanceMode: .continuousAutoWhiteBalance
    )

    /// Professional 4K configuration: UHD 4K, 30 fps, P010, BT.2020, HDR10.
    public static let pro4K = VideoSourceConfiguration(
        resolution: .uhd4K,
        frameRate: .fps30,
        pixelFormat: .p010,
        colorSpace: .bt2020,
        dynamicRange: .hdr10,
        stabilization: .off,
        focusMode: .continuousAutoFocus,
        exposureMode: .continuousAutoExposure,
        whiteBalanceMode: .continuousAutoWhiteBalance
    )

    /// Cinematic configuration: 1080p, 24 fps, Display P3, cinematic stabilization.
    public static let cinematic = VideoSourceConfiguration(
        resolution: .p1080,
        frameRate: .fps24,
        pixelFormat: .nv12,
        colorSpace: .displayP3,
        dynamicRange: .sdr,
        stabilization: .cinematic,
        focusMode: .continuousAutoFocus,
        exposureMode: .continuousAutoExposure,
        whiteBalanceMode: .continuousAutoWhiteBalance
    )

    /// Spatial video configuration: spatial resolution, 30 fps, BT.2020, HLG.
    public static let spatialVideo = VideoSourceConfiguration(
        resolution: .spatialVideo,
        frameRate: .fps30,
        pixelFormat: .nv12,
        colorSpace: .bt2020,
        dynamicRange: .hlg,
        stabilization: .off,
        focusMode: .continuousAutoFocus,
        exposureMode: .continuousAutoExposure,
        whiteBalanceMode: .continuousAutoWhiteBalance
    )

    /// Creates a new video source configuration.
    ///
    /// - Parameters:
    ///   - resolution: The desired resolution.
    ///   - frameRate: The desired frame rate.
    ///   - pixelFormat: The pixel format. Defaults to `.nv12`.
    ///   - colorSpace: The color space. Defaults to `.bt709`.
    ///   - dynamicRange: The dynamic range. Defaults to `.sdr`.
    ///   - stabilization: The stabilization mode. Defaults to `.off`.
    ///   - focusMode: The focus mode. Defaults to `.continuousAutoFocus`.
    ///   - exposureMode: The exposure mode. Defaults to `.continuousAutoExposure`.
    ///   - whiteBalanceMode: The white balance mode. Defaults to `.continuousAutoWhiteBalance`.
    public init(
        resolution: VideoResolution,
        frameRate: FrameRate,
        pixelFormat: PixelFormat = .nv12,
        colorSpace: ColorSpace = .bt709,
        dynamicRange: DynamicRange = .sdr,
        stabilization: VideoStabilization = .off,
        focusMode: FocusMode = .continuousAutoFocus,
        exposureMode: ExposureMode = .continuousAutoExposure,
        whiteBalanceMode: WhiteBalanceMode = .continuousAutoWhiteBalance
    ) {
        self.resolution = resolution
        self.frameRate = frameRate
        self.pixelFormat = pixelFormat
        self.colorSpace = colorSpace
        self.dynamicRange = dynamicRange
        self.stabilization = stabilization
        self.focusMode = focusMode
        self.exposureMode = exposureMode
        self.whiteBalanceMode = whiteBalanceMode
    }
}

/// A sample of frame capture and encoding statistics.
public struct FrameStatisticsSample: Sendable, Equatable {
    /// The timestamp of this statistics sample in seconds.
    public let timestamp: TimeInterval

    /// The measured frame rate of captured frames per second.
    public let capturedFrameRate: Double

    /// The total number of dropped frames.
    public let droppedFrames: Int

    /// The measured frame rate of encoded frames per second.
    public let encodedFrameRate: Double

    /// The average time to encode a single frame in seconds.
    public let averageEncodingTime: TimeInterval

    /// The current encoding bitrate in bits per second.
    public let currentBitrate: Double

    /// The interval between key frames in number of frames.
    public let keyFrameInterval: Int

    /// The current buffer fill level in number of frames.
    public let bufferLevel: Int

    /// Creates a new frame statistics sample.
    ///
    /// - Parameters:
    ///   - timestamp: The timestamp in seconds.
    ///   - capturedFrameRate: The captured frame rate.
    ///   - droppedFrames: The number of dropped frames.
    ///   - encodedFrameRate: The encoded frame rate.
    ///   - averageEncodingTime: The average encoding time in seconds.
    ///   - currentBitrate: The current bitrate in bits per second.
    ///   - keyFrameInterval: The key frame interval in frames.
    ///   - bufferLevel: The buffer fill level in frames.
    public init(
        timestamp: TimeInterval,
        capturedFrameRate: Double,
        droppedFrames: Int,
        encodedFrameRate: Double,
        averageEncodingTime: TimeInterval,
        currentBitrate: Double,
        keyFrameInterval: Int,
        bufferLevel: Int
    ) {
        self.timestamp = timestamp
        self.capturedFrameRate = capturedFrameRate
        self.droppedFrames = droppedFrames
        self.encodedFrameRate = encodedFrameRate
        self.averageEncodingTime = averageEncodingTime
        self.currentBitrate = currentBitrate
        self.keyFrameInterval = keyFrameInterval
        self.bufferLevel = bufferLevel
    }
}

/// Protocol for video capture sources.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public protocol VideoSource: Sendable {
    /// A unique identifier for this video source.
    var sourceID: String { get }

    /// A human-readable display name for this video source.
    var displayName: String { get }

    /// The type of this video source.
    var sourceType: VideoSourceType { get }

    /// The video formats supported by this source.
    var supportedFormats: [VideoFormat] { get async }

    /// The currently active video format, if any.
    var activeFormat: VideoFormat? { get async }

    /// Whether this source is currently capturing video.
    var isCapturing: Bool { get async }

    /// The availability status of this source on the current platform and device.
    var availability: SourceAvailability { get }

    /// Configures this video source with the given configuration.
    ///
    /// - Parameter configuration: The desired video source configuration.
    func configure(_ configuration: VideoSourceConfiguration) async throws

    /// Starts capturing video and returns an async stream of video frames.
    ///
    /// - Returns: An asynchronous stream of captured video frames.
    func startCapture() async throws -> AsyncStream<VideoFrame>

    /// Stops the current video capture.
    func stopCapture() async

    /// An asynchronous stream of frame capture and encoding statistics.
    var frameStatistics: AsyncStream<FrameStatisticsSample> { get }
}
