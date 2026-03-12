// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

#if canImport(VideoToolbox)
    import VideoToolbox
#endif

/// AV1 encoder via VideoToolbox.
///
/// Next-generation codec offering 30% better compression than HEVC.
/// Requires Apple M3 or later for hardware encoding.
public actor AV1Encoder: VideoEncoderProtocol {

    // MARK: - Properties

    /// The video codec used by this encoder.
    nonisolated public let codec: VideoCodec = .av1

    /// Current encoder configuration.
    public private(set) var configuration: AV1EncoderConfiguration
    /// Whether the encoder has been configured.
    public private(set) var isConfigured: Bool = false
    /// Whether a keyframe has been requested for the next frame.
    private var pendingKeyFrame: Bool = false
    /// The underlying encoder provider (VideoToolbox or passthrough).
    private let encoderProvider: any VideoEncoderProviding
    /// Whether to skip the hardware support check (for testing with mock providers).
    private let skipHardwareCheck: Bool

    // MARK: - Protocol Computed Properties

    /// Resolutions supported by this encoder.
    nonisolated public var supportedResolutions: [VideoResolution] {
        [.p720, .p1080, .p1440, .uhd4K]
    }

    /// Frame rates supported by this encoder.
    nonisolated public var supportedFrameRates: [FrameRate] {
        [.fps24, .fps25, .fps29_97, .fps30, .fps50, .fps59_94, .fps60]
    }

    /// Bitrate range supported by this encoder (bits per second).
    nonisolated public var supportedBitRates: ClosedRange<Int> {
        100_000...100_000_000
    }

    /// Encoding profiles supported by this encoder.
    nonisolated public var supportedProfiles: [String] {
        AV1Profile.allCases.map(\.rawValue)
    }

    /// Whether this encoder uses hardware acceleration.
    ///
    /// Performs a real VideoToolbox probe rather than returning a
    /// hard-coded value, so devices that only *decode* AV1 (but
    /// cannot encode) correctly report `false`.
    nonisolated public var isHardwareAccelerated: Bool {
        Self._hardwareEncodingAvailable
    }

    /// Cached result of the AV1 hardware encoding probe.
    /// Evaluated once (lazily, thread-safe) via `static let`.
    private static let _hardwareEncodingAvailable: Bool = {
        #if canImport(VideoToolbox)
            // Reuse the same two-stage probe used by configure().
            var properties: CFDictionary?
            let queryStatus = VTCopySupportedPropertyDictionaryForEncoder(
                width: 1920,
                height: 1080,
                codecType: kCMVideoCodecType_AV1,
                encoderSpecification: nil,
                encoderIDOut: nil,
                supportedPropertiesOut: &properties
            )
            if queryStatus == noErr {
                return true
            }

            var session: VTCompressionSession?
            let createStatus = VTCompressionSessionCreate(
                allocator: kCFAllocatorDefault,
                width: 1920,
                height: 1080,
                codecType: kCMVideoCodecType_AV1,
                encoderSpecification: nil,
                imageBufferAttributes: nil,
                compressedDataAllocator: nil,
                outputCallback: nil,
                refcon: nil,
                compressionSessionOut: &session
            )
            if createStatus == noErr, let session {
                VTCompressionSessionInvalidate(session)
                return true
            }
            return false
        #else
            return false
        #endif
    }()

    // MARK: - Initialization

    /// Creates a new encoder with the given configuration.
    public init(configuration: AV1EncoderConfiguration = .streaming1080p) {
        self.configuration = configuration
        self.skipHardwareCheck = false
        #if canImport(VideoToolbox)
            self.encoderProvider = VideoToolboxEncoder()
        #else
            self.encoderProvider = PassthroughVideoEncoder()
        #endif
    }

    /// Creates a new encoder with an injected provider (for testing).
    init(configuration: AV1EncoderConfiguration = .streaming1080p, encoderProvider: any VideoEncoderProviding) {
        self.configuration = configuration
        self.encoderProvider = encoderProvider
        self.skipHardwareCheck = true
    }

    // MARK: - VideoEncoderProtocol

    /// Configures the encoder with generic video settings.
    ///
    /// - Throws: ``CaptureError/encoderNotAvailable(codec:reason:)`` if AV1
    ///   hardware encoding is not supported on the current device (requires M3+/A17 Pro+).
    public func configure(_ config: VideoEncoderConfiguration) async throws {
        if !skipHardwareCheck {
            try Self.checkAV1Support(
                width: config.resolution.width,
                height: config.resolution.height
            )
        }

        let av1Config = AV1EncoderConfiguration(
            bitrate: config.bitrate,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime
        )
        self.configuration = av1Config

        try await encoderProvider.configure(
            width: config.resolution.width,
            height: config.resolution.height,
            codec: .av1,
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
                codec: "AV1",
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
        self.configuration = AV1EncoderConfiguration(
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

    /// Configures with AV1-specific settings.
    ///
    /// - Throws: ``CaptureError/encoderNotAvailable(codec:reason:)`` if AV1
    ///   hardware encoding is not supported on the current device.
    public func configure(av1 config: AV1EncoderConfiguration) async throws {
        if !skipHardwareCheck {
            try Self.checkAV1Support(width: 1920, height: 1080)
        }

        self.configuration = config

        try await encoderProvider.configure(
            width: 1920, height: 1080,
            codec: .av1,
            bitrate: config.bitrate,
            frameRate: 30.0,
            keyFrameInterval: config.keyFrameInterval,
            realTime: config.realTime,
            profileLevel: config.profile.rawValue
        )
        self.isConfigured = true
    }

    // MARK: - AV1 Support Check

    private static func checkAV1Support(width: Int, height: Int) throws {
        #if canImport(VideoToolbox)
            // First try VTCopySupportedPropertyDictionaryForEncoder
            var properties: CFDictionary?
            let queryStatus = VTCopySupportedPropertyDictionaryForEncoder(
                width: Int32(width),
                height: Int32(height),
                codecType: kCMVideoCodecType_AV1,
                encoderSpecification: nil,
                encoderIDOut: nil,
                supportedPropertiesOut: &properties
            )
            if queryStatus == noErr {
                return
            }

            // Fallback: Try creating a session directly.
            // On some Apple Silicon chips (M4+), the query API may fail
            // but the encoder is available via direct session creation.
            var session: VTCompressionSession?
            let createStatus = VTCompressionSessionCreate(
                allocator: kCFAllocatorDefault,
                width: Int32(width),
                height: Int32(height),
                codecType: kCMVideoCodecType_AV1,
                encoderSpecification: nil,
                imageBufferAttributes: nil,
                compressedDataAllocator: nil,
                outputCallback: nil,
                refcon: nil,
                compressionSessionOut: &session
            )
            if createStatus == noErr, let session {
                VTCompressionSessionInvalidate(session)
                return
            }

            throw CaptureError.encoderNotAvailable(
                codec: "av1",
                reason: "AV1 hardware encoding is not available on this device"
            )
        #endif
    }
}
