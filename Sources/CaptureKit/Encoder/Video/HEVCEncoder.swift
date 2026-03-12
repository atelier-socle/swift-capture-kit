// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

#if canImport(VideoToolbox)
    import CoreMedia
    import VideoToolbox
#endif

/// HEVC/H.265 encoder via VideoToolbox.
///
/// 50% more efficient than H.264 at the same quality. Supports HDR10, HLG,
/// Dolby Vision, and alpha channel encoding. Hardware-accelerated on all Apple Silicon.
public actor HEVCEncoder: VideoEncoderProtocol {

    // MARK: - Properties

    /// The video codec used by this encoder.
    nonisolated public let codec: VideoCodec = .hevc

    /// Current encoder configuration.
    public private(set) var configuration: HEVCEncoderConfiguration
    /// Whether the encoder has been configured.
    public private(set) var isConfigured: Bool = false
    /// Whether a keyframe has been requested for the next frame.
    private var pendingKeyFrame: Bool = false
    /// The underlying encoder provider (VideoToolbox or passthrough).
    private let encoderProvider: any VideoEncoderProviding

    // MARK: - Protocol Computed Properties

    /// Resolutions supported by this encoder.
    nonisolated public var supportedResolutions: [VideoResolution] {
        [.qvga, .vga, .p540, .p720, .p1080, .p1440, .uhd4K, .dci4K, .uhd8K]
    }

    /// Frame rates supported by this encoder.
    nonisolated public var supportedFrameRates: [FrameRate] {
        [.fps15, .fps24, .fps25, .fps29_97, .fps30, .fps50, .fps59_94, .fps60, .fps120]
    }

    /// Bitrate range supported by this encoder (bits per second).
    nonisolated public var supportedBitRates: ClosedRange<Int> {
        100_000...200_000_000
    }

    /// Encoding profiles supported by this encoder.
    nonisolated public var supportedProfiles: [String] {
        HEVCProfile.allCases.map(\.rawValue)
    }

    /// Whether this encoder uses hardware acceleration.
    nonisolated public var isHardwareAccelerated: Bool {
        true
    }

    // MARK: - Parameter Sets

    /// HEVC parameter sets extracted from the encoder session.
    public struct HEVCParameterSets: Sendable {
        /// Video Parameter Set NAL unit bytes (without start codes).
        public let vps: Data
        /// Sequence Parameter Set NAL unit bytes (without start codes).
        public let sps: Data
        /// Picture Parameter Set NAL unit bytes (without start codes).
        public let pps: Data
    }

    /// The HEVC parameter sets (VPS, SPS, PPS) from the current encoder session.
    ///
    /// Available after the first successful ``encode(_:)`` call. Returns `nil`
    /// if the encoder has not yet produced output or if VideoToolbox is unavailable.
    ///
    /// These are the raw NAL unit bytes **without** Annex B start codes.
    public var parameterSets: HEVCParameterSets? {
        get async {
            #if canImport(VideoToolbox)
                guard let sendable = await encoderProvider.formatDescription else {
                    return nil
                }
                return Self.extractHEVCParameterSets(from: sendable)
            #else
                return nil
            #endif
        }
    }

    #if canImport(VideoToolbox)
        /// Extract VPS, SPS, and PPS from an HEVC format description.
        nonisolated static func extractHEVCParameterSets(
            from sendable: any Sendable
        ) -> HEVCParameterSets? {
            let ref = sendable as CFTypeRef
            guard CFGetTypeID(ref) == CMFormatDescriptionGetTypeID() else {
                return nil
            }
            let desc = unsafeDowncast(ref as AnyObject, to: CMFormatDescription.self)

            guard
                let vps = hevcParameterSet(from: desc, index: 0),
                let sps = hevcParameterSet(from: desc, index: 1),
                let pps = hevcParameterSet(from: desc, index: 2)
            else {
                return nil
            }
            return HEVCParameterSets(vps: vps, sps: sps, pps: pps)
        }

        private nonisolated static func hevcParameterSet(
            from desc: CMFormatDescription, index: Int
        ) -> Data? {
            var size = 0
            var pointer: UnsafePointer<UInt8>?
            let status = CMVideoFormatDescriptionGetHEVCParameterSetAtIndex(
                desc,
                parameterSetIndex: index,
                parameterSetPointerOut: &pointer,
                parameterSetSizeOut: &size,
                parameterSetCountOut: nil,
                nalUnitHeaderLengthOut: nil
            )
            guard status == noErr, let pointer, size > 0 else {
                return nil
            }
            return Data(bytes: pointer, count: size)
        }
    #endif

    // MARK: - Initialization

    /// Creates a new encoder with the given configuration.
    public init(configuration: HEVCEncoderConfiguration = .streaming1080p) {
        self.configuration = configuration
        #if canImport(VideoToolbox)
            self.encoderProvider = VideoToolboxEncoder()
        #else
            self.encoderProvider = PassthroughVideoEncoder()
        #endif
    }

    /// Creates a new encoder with an injected provider (for testing).
    init(configuration: HEVCEncoderConfiguration = .streaming1080p, encoderProvider: any VideoEncoderProviding) {
        self.configuration = configuration
        self.encoderProvider = encoderProvider
    }

    // MARK: - VideoEncoderProtocol

    /// Configures the encoder with generic video settings.
    public func configure(_ config: VideoEncoderConfiguration) async throws {
        let hevcConfig = HEVCEncoderConfiguration(
            bitrate: config.bitrate,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime
        )
        try hevcConfig.validate()
        self.configuration = hevcConfig

        try await encoderProvider.configure(
            width: config.resolution.width,
            height: config.resolution.height,
            codec: .hevc,
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
                codec: "HEVC",
                reason: "Encoder is not configured"
            )
        }

        let requestKey = pendingKeyFrame
        let encoded = try await encoderProvider.encode(
            data: frame.data,
            width: frame.format.resolution.width,
            height: frame.format.resolution.height,
            timestamp: frame.timestamp,
            isKeyFrame: requestKey
        )
        pendingKeyFrame = false
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
        self.configuration = HEVCEncoderConfiguration(
            resolution: configuration.resolution,
            frameRate: configuration.frameRate,
            bitrate: bitrate,
            keyFrameInterval: configuration.keyFrameInterval,
            realTime: configuration.realTime
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

    /// Configures with HEVC-specific settings.
    public func configure(hevc config: HEVCEncoderConfiguration) async throws {
        try config.validate()
        self.configuration = config

        try await encoderProvider.configure(
            width: config.resolution.width,
            height: config.resolution.height,
            codec: .hevc,
            bitrate: config.bitrate,
            frameRate: config.frameRate.value,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime,
            profileLevel: config.profile.rawValue
        )
        self.isConfigured = true
    }
}
