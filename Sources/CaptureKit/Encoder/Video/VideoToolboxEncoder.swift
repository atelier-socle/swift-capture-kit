// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if canImport(VideoToolbox)
    @preconcurrency import CoreMedia
    @preconcurrency import VideoToolbox
    import Foundation

    /// Thread-safe buffer for encoded data from VTCompressionSession callback.
    ///
    /// @unchecked Sendable justification: Only accessed from the actor executor
    /// (during encode/flush/reset) or from VideoToolbox's internal thread during
    /// VTCompressionSessionCompleteFrames, which runs synchronously while the
    /// actor executor is blocked. No concurrent access occurs.
    private final class EncodedVideoDataBuffer: @unchecked Sendable {
        var data = Data()
        var formatDescription: CMFormatDescription?
        /// Whether the last encoded frame was a sync (key) frame,
        /// as reported by VideoToolbox sample buffer attachments.
        var isKeyFrame = false
    }

    /// C callback for VTCompressionSession output.
    private let vtCompressionOutputCallback: VTCompressionOutputCallback = { refcon, _, status, _, sampleBuffer in
        guard status == noErr, let sampleBuffer, let refcon else {
            return
        }
        let buffer = Unmanaged<EncodedVideoDataBuffer>
            .fromOpaque(refcon).takeUnretainedValue()
        guard
            let dataBuffer = CMSampleBufferGetDataBuffer(
                sampleBuffer)
        else { return }
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(
            dataBuffer, atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer)
        if let dataPointer {
            buffer.data.append(
                Data(bytes: dataPointer, count: length))
        }
        if buffer.formatDescription == nil {
            buffer.formatDescription =
                CMSampleBufferGetFormatDescription(sampleBuffer)
        }
        // Determine keyframe status from sample buffer attachments.
        // kCMSampleAttachmentKey_DependsOnOthers is the most reliable indicator:
        // absent or false → keyframe (IDR), true → P/B-frame.
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(
            sampleBuffer, createIfNecessary: false) as? [[CFString: Any]],
           let first = attachments.first {
            let dependsOnOthers = first[kCMSampleAttachmentKey_DependsOnOthers] as? Bool ?? false
            buffer.isKeyFrame = !dependsOnOthers
        } else {
            // No attachments → treat as keyframe (IDR).
            buffer.isKeyFrame = true
        }
    }

    /// Real video encoder using VideoToolbox VTCompressionSession.
    ///
    /// Supports H.264, HEVC, ProRes, AV1, MV-HEVC, JPEG.
    /// Actor isolation protects the non-Sendable VTCompressionSession.
    @available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
    actor VideoToolboxEncoder: VideoEncoderProviding {
        private var compressionSession: VTCompressionSession?
        private var forceNextKeyFrame = false
        private let encodedBuffer = EncodedVideoDataBuffer()

        func configure(
            width: Int, height: Int,
            codec: VideoCodec, bitrate: Int?,
            frameRate: Double, keyFrameInterval: Int?,
            realTime: Bool, profileLevel: String?
        ) async throws {
            dispose()

            let codecType = vtCodecType(for: codec)
            let refcon = Unmanaged.passUnretained(encodedBuffer)
                .toOpaque()

            var session: VTCompressionSession?
            let status = VTCompressionSessionCreate(
                allocator: kCFAllocatorDefault,
                width: Int32(width),
                height: Int32(height),
                codecType: codecType,
                encoderSpecification: nil,
                imageBufferAttributes: nil,
                compressedDataAllocator: nil,
                outputCallback: vtCompressionOutputCallback,
                refcon: refcon,
                compressionSessionOut: &session
            )

            guard status == noErr, let session else {
                throw CaptureError.encoderConfigurationFailed(
                    codec: codec.rawValue,
                    reason:
                        "VTCompressionSessionCreate failed: \(status)"
                )
            }

            setSessionProperties(
                session: session,
                bitrate: bitrate,
                frameRate: frameRate,
                keyFrameInterval: keyFrameInterval,
                realTime: realTime,
                profileLevel: profileLevel
            )

            VTCompressionSessionPrepareToEncodeFrames(session)
            self.compressionSession = session
        }

        func encode(
            data: Data, width: Int, height: Int,
            timestamp: TimeInterval, isKeyFrame: Bool
        ) async throws -> Data {
            guard let session = compressionSession else {
                throw CaptureError.encodingFailed(
                    codec: "video",
                    reason: "Encoder not configured"
                )
            }

            let pixelBuffer = try createPixelBuffer(
                from: data, width: width, height: height)

            let pts = CMTime(
                seconds: timestamp, preferredTimescale: 90000)
            var properties: [CFString: Any] = [:]
            if forceNextKeyFrame || isKeyFrame {
                properties[kVTEncodeFrameOptionKey_ForceKeyFrame] =
                    true
                forceNextKeyFrame = false
            }

            encodedBuffer.data = Data()

            let encodeStatus =
                VTCompressionSessionEncodeFrame(
                    session,
                    imageBuffer: pixelBuffer,
                    presentationTimeStamp: pts,
                    duration: .invalid,
                    frameProperties: properties.isEmpty
                        ? nil : properties as CFDictionary,
                    sourceFrameRefcon: nil,
                    infoFlagsOut: nil
                )

            guard encodeStatus == noErr else {
                throw CaptureError.encodingFailed(
                    codec: "video",
                    reason:
                        "VTCompressionSessionEncodeFrame failed: \(encodeStatus)"
                )
            }

            VTCompressionSessionCompleteFrames(
                session,
                untilPresentationTimeStamp: .invalid)

            return encodedBuffer.data
        }

        func forceKeyFrame() async throws {
            forceNextKeyFrame = true
        }

        func updateBitrate(_ bitrate: Int) async throws {
            guard let session = compressionSession else { return }
            VTSessionSetProperty(
                session,
                key: kVTCompressionPropertyKey_AverageBitRate,
                value: bitrate as CFNumber
            )
        }

        func flush() async throws -> Data? {
            guard let session = compressionSession else {
                return nil
            }
            VTCompressionSessionCompleteFrames(
                session,
                untilPresentationTimeStamp: .invalid)
            let result =
                encodedBuffer.data.isEmpty
                ? nil : encodedBuffer.data
            encodedBuffer.data = Data()
            return result
        }

        var formatDescription: (any Sendable)? {
            encodedBuffer.formatDescription
        }

        var lastFrameIsKeyFrame: Bool {
            encodedBuffer.isKeyFrame
        }

        func reset() async {
            dispose()
            encodedBuffer.data = Data()
            encodedBuffer.formatDescription = nil
        }

        /// Disposes the compression session.
        func dispose() {
            if let session = compressionSession {
                VTCompressionSessionInvalidate(session)
            }
            compressionSession = nil
        }

        // MARK: - Private Helpers

        private func createPixelBuffer(
            from data: Data, width: Int, height: Int
        ) throws -> CVPixelBuffer {
            var pixelBuffer: CVPixelBuffer?
            let attrs: [CFString: Any] = [
                kCVPixelBufferWidthKey: width,
                kCVPixelBufferHeightKey: height,
                kCVPixelBufferPixelFormatTypeKey:
                    kCVPixelFormatType_32BGRA
            ]
            CVPixelBufferCreate(
                kCFAllocatorDefault, width, height,
                kCVPixelFormatType_32BGRA,
                attrs as CFDictionary,
                &pixelBuffer
            )

            guard let buffer = pixelBuffer else {
                throw CaptureError.encodingFailed(
                    codec: "video",
                    reason: "Failed to create pixel buffer"
                )
            }

            CVPixelBufferLockBaseAddress(buffer, [])
            if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
                data.withUnsafeBytes { ptr in
                    guard let srcBase = ptr.baseAddress else {
                        return
                    }
                    let count = min(
                        data.count,
                        CVPixelBufferGetBytesPerRow(buffer)
                            * height)
                    baseAddress.copyMemory(
                        from: srcBase, byteCount: count)
                }
            }
            CVPixelBufferUnlockBaseAddress(buffer, [])

            return buffer
        }

        private func setSessionProperties(
            session: VTCompressionSession,
            bitrate: Int?,
            frameRate: Double,
            keyFrameInterval: Int?,
            realTime: Bool,
            profileLevel: String?
        ) {
            VTSessionSetProperty(
                session,
                key: kVTCompressionPropertyKey_RealTime,
                value: realTime as CFBoolean
            )

            if let bitrate {
                VTSessionSetProperty(
                    session,
                    key: kVTCompressionPropertyKey_AverageBitRate,
                    value: bitrate as CFNumber
                )
            }

            if let keyFrameInterval {
                VTSessionSetProperty(
                    session,
                    key:
                        kVTCompressionPropertyKey_MaxKeyFrameInterval,
                    value: keyFrameInterval as CFNumber
                )
            }

            VTSessionSetProperty(
                session,
                key: kVTCompressionPropertyKey_ExpectedFrameRate,
                value: frameRate as CFNumber
            )

            if let profileLevel {
                VTSessionSetProperty(
                    session,
                    key: kVTCompressionPropertyKey_ProfileLevel,
                    value: profileLevel as CFString
                )
            }
        }

        private func vtCodecType(
            for codec: VideoCodec
        ) -> CMVideoCodecType {
            switch codec {
            case .h264: return kCMVideoCodecType_H264
            case .hevc: return kCMVideoCodecType_HEVC
            case .prores: return kCMVideoCodecType_AppleProRes422HQ
            case .av1: return kCMVideoCodecType_AV1
            case .mvHevc: return kCMVideoCodecType_HEVC
            case .jpeg: return kCMVideoCodecType_JPEG
            }
        }
    }
#endif
