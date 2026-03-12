// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

#if canImport(VideoToolbox)
    import CoreMedia
    import VideoToolbox
#endif

/// H.264/AVC encoder via VideoToolbox.
///
/// The most widely compatible video codec. Hardware-accelerated on all Apple devices.
/// Supports Baseline, Main, High, and High10 profiles with configurable entropy mode,
/// B-frames, and bitrate control.
public actor H264Encoder: VideoEncoderProtocol {

    // MARK: - Properties

    /// The video codec used by this encoder.
    nonisolated public let codec: VideoCodec = .h264

    /// Current encoder configuration.
    public private(set) var configuration: H264EncoderConfiguration
    /// Whether the encoder has been configured.
    public private(set) var isConfigured: Bool = false
    /// Whether a keyframe has been requested for the next frame.
    private var pendingKeyFrame: Bool = false
    /// The underlying encoder provider (VideoToolbox or passthrough).
    private let encoderProvider: any VideoEncoderProviding

    // MARK: - Protocol Computed Properties

    /// Resolutions supported by this encoder.
    nonisolated public var supportedResolutions: [VideoResolution] {
        [.qvga, .vga, .p540, .p720, .p1080, .p1440, .uhd4K]
    }

    /// Frame rates supported by this encoder.
    nonisolated public var supportedFrameRates: [FrameRate] {
        [.fps15, .fps24, .fps25, .fps29_97, .fps30, .fps50, .fps59_94, .fps60]
    }

    /// Bitrate range supported by this encoder (bits per second).
    nonisolated public var supportedBitRates: ClosedRange<Int> {
        100_000...100_000_000
    }

    /// Encoding profiles supported by this encoder.
    nonisolated public var supportedProfiles: [String] {
        H264Profile.allCases.map(\.rawValue)
    }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool {
        true
    }

    // MARK: - Parameter Sets

    /// The H.264 parameter sets (SPS, PPS) from the current encoder session.
    ///
    /// Available after the first successful ``encode(_:)`` call. Returns `nil`
    /// if the encoder has not yet produced output or if VideoToolbox is unavailable.
    ///
    /// These are the raw NAL unit bytes **without** Annex B start codes.
    /// Use them to build an AVCDecoderConfigurationRecord for RTMP or
    /// to supply codec configuration for HLS/MPEG-TS packaging.
    /// The H.264 parameter sets (SPS, PPS) from the current encoder session.
    ///
    /// Available after the first successful ``encode(_:)`` call. Returns `nil`
    /// if the encoder has not yet produced output or if VideoToolbox is unavailable.
    ///
    /// These are the raw NAL unit bytes **without** Annex B start codes.
    /// Use them to build an AVCDecoderConfigurationRecord for RTMP or
    /// to supply codec configuration for HLS/MPEG-TS packaging.
    public var parameterSets: (sps: Data, pps: Data)? {
        get async {
            #if canImport(VideoToolbox)
                guard let sendable = await encoderProvider.formatDescription else {
                    return nil
                }
                return Self.extractH264ParameterSets(from: sendable)
            #else
                return nil
            #endif
        }
    }

    #if canImport(VideoToolbox)
        /// Extract SPS and PPS from an H.264 format description.
        ///
        /// - Parameter sendable: The format description as `any Sendable`
        ///   (expected to be a `CMFormatDescription`).
        /// - Returns: The SPS and PPS data, or `nil` if extraction fails.
        nonisolated static func extractH264ParameterSets(
            from sendable: any Sendable
        ) -> (sps: Data, pps: Data)? {
            let ref = sendable as CFTypeRef
            guard CFGetTypeID(ref) == CMFormatDescriptionGetTypeID() else {
                return nil
            }
            let desc = unsafeDowncast(ref as AnyObject, to: CMFormatDescription.self)

            var spsSize = 0
            var spsPointer: UnsafePointer<UInt8>?
            let spsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                desc,
                parameterSetIndex: 0,
                parameterSetPointerOut: &spsPointer,
                parameterSetSizeOut: &spsSize,
                parameterSetCountOut: nil,
                nalUnitHeaderLengthOut: nil
            )
            guard spsStatus == noErr, let spsPointer, spsSize > 0 else {
                return nil
            }
            let sps = Data(bytes: spsPointer, count: spsSize)

            var ppsSize = 0
            var ppsPointer: UnsafePointer<UInt8>?
            let ppsStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                desc,
                parameterSetIndex: 1,
                parameterSetPointerOut: &ppsPointer,
                parameterSetSizeOut: &ppsSize,
                parameterSetCountOut: nil,
                nalUnitHeaderLengthOut: nil
            )
            guard ppsStatus == noErr, let ppsPointer, ppsSize > 0 else {
                return nil
            }
            let pps = Data(bytes: ppsPointer, count: ppsSize)

            return (sps: sps, pps: pps)
        }
    #endif

    // MARK: - Initialization

    /// Creates a new encoder with the given configuration.
    public init(configuration: H264EncoderConfiguration = .streaming1080p) {
        self.configuration = configuration
        #if canImport(VideoToolbox)
            self.encoderProvider = VideoToolboxEncoder()
        #else
            self.encoderProvider = PassthroughVideoEncoder()
        #endif
    }

    /// Creates a new encoder with an injected provider (for testing).
    init(configuration: H264EncoderConfiguration = .streaming1080p, encoderProvider: any VideoEncoderProviding) {
        self.configuration = configuration
        self.encoderProvider = encoderProvider
    }

    // MARK: - VideoEncoderProtocol

    /// Configures the encoder with generic video settings.
    public func configure(_ config: VideoEncoderConfiguration) async throws {
        let h264Config = H264EncoderConfiguration(
            bitrate: config.bitrate,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime
        )
        try h264Config.validate()
        self.configuration = h264Config

        try await encoderProvider.configure(
            width: config.resolution.width,
            height: config.resolution.height,
            codec: .h264,
            bitrate: config.bitrate,
            frameRate: config.frameRate.value,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime,
            profileLevel: configuration.profile.rawValue
        )
        self.isConfigured = true
    }

    /// Encodes a video frame.
    public func encode(_ frame: VideoFrame) async throws -> EncodedVideoFrame {
        guard isConfigured else {
            throw CaptureError.encoderConfigurationFailed(
                codec: "H.264",
                reason: "Encoder is not configured"
            )
        }

        // Only force keyframe when explicitly requested via forceKeyFrame().
        // Raw VideoFrame.isKeyFrame is always true (uncompressed frames are
        // independent) and must NOT be forwarded to VT — it would override
        // the GOP interval and produce all-keyframes.
        let requestKey = pendingKeyFrame
        let encoded = try await encoderProvider.encode(
            data: frame.data,
            width: frame.format.resolution.width,
            height: frame.format.resolution.height,
            timestamp: frame.timestamp,
            isKeyFrame: requestKey
        )
        pendingKeyFrame = false
        // Use the actual keyframe status from the encoder output
        // (CMSampleBuffer attachments), not the input request.
        let actualIsKey = await encoderProvider.lastFrameIsKeyFrame
        return EncodedVideoFrame(
            data: encoded,
            codec: codec,
            timestamp: frame.timestamp,
            isKeyFrame: actualIsKey,
            sequenceNumber: frame.sequenceNumber
        )
    }

    /// Requests the next encoded frame to be a keyframe.
    public func forceKeyFrame() async throws {
        try await encoderProvider.forceKeyFrame()
        pendingKeyFrame = true
    }

    /// Updates the target bitrate dynamically.
    public func updateBitrate(_ bitrate: Int) async throws {
        try await encoderProvider.updateBitrate(bitrate)
        self.configuration = H264EncoderConfiguration(
            profile: configuration.profile,
            level: configuration.level,
            resolution: configuration.resolution,
            frameRate: configuration.frameRate,
            bitrate: bitrate,
            bitrateMode: configuration.bitrateMode,
            keyFrameInterval: configuration.keyFrameInterval,
            bFrames: configuration.bFrames,
            entropyMode: configuration.entropyMode,
            realTime: configuration.realTime,
            maxSliceBytes: configuration.maxSliceBytes
        )
    }

    /// Flushes any buffered frames.
    public func flush() async throws -> [EncodedVideoFrame] {
        guard let data = try await encoderProvider.flush() else {
            return []
        }
        return [
            EncodedVideoFrame(
                data: data, codec: codec,
                timestamp: 0, isKeyFrame: false, sequenceNumber: -1
            )
        ]
    }

    /// Resets the encoder to its unconfigured state.
    public func reset() async {
        await encoderProvider.reset()
        isConfigured = false
        pendingKeyFrame = false
    }

    // MARK: - Codec-Specific Configuration

    /// Configures with H.264-specific settings.
    public func configure(h264 config: H264EncoderConfiguration) async throws {
        try config.validate()
        self.configuration = config

        try await encoderProvider.configure(
            width: config.resolution.width,
            height: config.resolution.height,
            codec: .h264,
            bitrate: config.bitrate,
            frameRate: config.frameRate.value,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime,
            profileLevel: config.profile.rawValue
        )
        self.isConfigured = true
    }
}
