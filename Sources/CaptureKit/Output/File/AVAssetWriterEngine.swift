// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

@preconcurrency import AVFoundation
import CoreVideo
import Foundation

#if canImport(AudioToolbox)
    import AudioToolbox
#endif

/// Real file writer using AVAssetWriter.
///
/// Actor isolation protects the non-Sendable AVAssetWriter.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor AVAssetWriterEngine: FileWriterProviding {
    private var writer: AVAssetWriter?
    private var audioInput: AVAssetWriterInput?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var videoWidth: Int = 0
    private var videoHeight: Int = 0
    private var _bytesWritten: Int64 = 0
    private var sessionStarted = false
    private var storedAudioFormat: AudioFormat?
    private var audioFormatDescription: CMAudioFormatDescription?

    var bytesWritten: Int64 { _bytesWritten }

    func prepare(
        url: URL,
        container: FileContainer,
        audioFormat: AudioFormat?,
        videoFormat: VideoFormat?
    ) async throws {
        _bytesWritten = 0
        storedAudioFormat = audioFormat
        audioFormatDescription = nil
        let fileType = avFileType(for: container)
        let assetWriter = try AVAssetWriter(
            outputURL: url, fileType: fileType)

        var pendingAudioInput: AVAssetWriterInput?
        var pendingVideoInput: AVAssetWriterInput?
        var pendingAdaptor: AVAssetWriterInputPixelBufferAdaptor?

        if let audioFormat {
            let settings = audioOutputSettings(for: audioFormat)
            let input = AVAssetWriterInput(
                mediaType: .audio, outputSettings: settings)
            input.expectsMediaDataInRealTime = true
            if assetWriter.canAdd(input) {
                assetWriter.add(input)
                pendingAudioInput = input
            }
        }

        if let videoFormat {
            let settings = videoOutputSettings(for: videoFormat)
            let input = AVAssetWriterInput(
                mediaType: .video, outputSettings: settings)
            input.expectsMediaDataInRealTime = true
            if assetWriter.canAdd(input) {
                assetWriter.add(input)
                pendingVideoInput = input
                self.videoWidth = videoFormat.resolution.width
                self.videoHeight = videoFormat.resolution.height

                let sourceAttrs: [String: Any] = [
                    kCVPixelBufferPixelFormatTypeKey as String:
                        Int(kCVPixelFormatType_32BGRA),
                    kCVPixelBufferWidthKey as String:
                        videoFormat.resolution.width,
                    kCVPixelBufferHeightKey as String:
                        videoFormat.resolution.height
                ]
                pendingAdaptor =
                    AVAssetWriterInputPixelBufferAdaptor(
                        assetWriterInput: input,
                        sourcePixelBufferAttributes: sourceAttrs)
            }
        }

        guard assetWriter.startWriting() else {
            throw CaptureError.outputPrepareFailed(
                outputID: "file-writer",
                reason: assetWriter.error?.localizedDescription
                    ?? "Unknown AVAssetWriter error"
            )
        }
        assetWriter.startSession(atSourceTime: .zero)
        sessionStarted = true
        self.writer = assetWriter
        self.audioInput = pendingAudioInput
        self.videoInput = pendingVideoInput
        self.pixelBufferAdaptor = pendingAdaptor
    }

    func writeAudio(
        _ data: Data,
        codec: AudioCodec,
        timestamp: TimeInterval,
        duration: TimeInterval
    ) async throws {
        guard let audioInput, audioInput.isReadyForMoreMediaData
        else { return }

        let formatDesc = getOrCreateAudioFormatDescription(
            codec: codec)
        let cmTime = CMTime(
            seconds: timestamp, preferredTimescale: 48_000)
        if let sampleBuffer = createAudioSampleBuffer(
            data: data, timestamp: cmTime, duration: duration,
            formatDescription: formatDesc)
        {
            if audioInput.append(sampleBuffer) {
                _bytesWritten += Int64(data.count)
            }
        }
    }

    func writeVideo(
        _ data: Data,
        codec: VideoCodec,
        timestamp: TimeInterval,
        isKeyFrame: Bool
    ) async throws {
        guard let videoInput, videoInput.isReadyForMoreMediaData,
            let adaptor = pixelBufferAdaptor
        else { return }

        let width = videoWidth
        let height = videoHeight
        guard width > 0, height > 0 else { return }

        let cmTime = CMTime(
            seconds: timestamp, preferredTimescale: 90_000)

        guard
            let pixelBuffer = createPixelBuffer(
                from: data, width: width, height: height,
                adaptor: adaptor)
        else { return }

        adaptor.append(pixelBuffer, withPresentationTime: cmTime)
        _bytesWritten += Int64(data.count)
    }

    func finalize() async throws {
        audioInput?.markAsFinished()
        videoInput?.markAsFinished()
        if let writer, writer.status == .writing {
            await writer.finishWriting()
        }
        self.writer = nil
        self.audioInput = nil
        self.videoInput = nil
        self.pixelBufferAdaptor = nil
        self.audioFormatDescription = nil
        sessionStarted = false
    }

    // MARK: - Private Helpers

    private func avFileType(
        for container: FileContainer
    ) -> AVFileType {
        switch container {
        case .mp4: .mp4
        case .mov: .mov
        case .m4a: .m4a
        case .caf: .caf
        case .wav: .wav
        case .aiff: .aiff
        case .flac: .mp4
        }
    }

    private func audioOutputSettings(
        for format: AudioFormat
    ) -> [String: Any]? {
        // Pass nil to let AVAssetWriter accept pre-encoded audio data.
        nil
    }

    private func videoOutputSettings(
        for format: VideoFormat
    ) -> [String: Any]? {
        [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: format.resolution.width,
            AVVideoHeightKey: format.resolution.height
        ]
    }

    private func createAudioSampleBuffer(
        data: Data,
        timestamp: CMTime,
        duration: TimeInterval,
        formatDescription: CMAudioFormatDescription?
    ) -> CMSampleBuffer? {
        var blockBuffer: CMBlockBuffer?
        let length = data.count

        var status = CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: length,
            blockAllocator: kCFAllocatorDefault,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: length,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        guard status == noErr, let blockBuffer else { return nil }

        status = data.withUnsafeBytes { rawBuffer in
            guard let src = rawBuffer.baseAddress else {
                return OSStatus(kCMBlockBufferNoErr + 1)
            }
            return CMBlockBufferReplaceDataBytes(
                with: src,
                blockBuffer: blockBuffer,
                offsetIntoDestination: 0,
                dataLength: length
            )
        }
        guard status == noErr else { return nil }

        var sampleBuffer: CMSampleBuffer?
        var timing = CMSampleTimingInfo(
            duration: CMTime(
                seconds: duration, preferredTimescale: 48_000),
            presentationTimeStamp: timestamp,
            decodeTimeStamp: .invalid
        )
        var sampleSize = length
        CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDescription,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 1,
            sampleSizeArray: &sampleSize,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }

    /// Creates or returns a cached CMAudioFormatDescription for the codec.
    private func getOrCreateAudioFormatDescription(
        codec: AudioCodec
    ) -> CMAudioFormatDescription? {
        if let existing = audioFormatDescription { return existing }

        #if canImport(AudioToolbox)
            let formatID: AudioFormatID = switch codec {
            case .aac: kAudioFormatMPEG4AAC
            case .alac: kAudioFormatAppleLossless
            case .opus: kAudioFormatOpus
            case .flac: kAudioFormatFLAC
            case .pcm: kAudioFormatLinearPCM
            case .mp3: kAudioFormatMPEGLayer3
            }

            let sampleRate =
                storedAudioFormat?.sampleRate.rawValue ?? 48000.0
            let channels = UInt32(
                storedAudioFormat?.channelCount ?? 1)

            var asbd = AudioStreamBasicDescription(
                mSampleRate: sampleRate,
                mFormatID: formatID,
                mFormatFlags: formatID == kAudioFormatLinearPCM
                    ? (kAudioFormatFlagIsFloat
                        | kAudioFormatFlagIsPacked) : 0,
                mBytesPerPacket: formatID == kAudioFormatLinearPCM
                    ? channels * 4 : 0,
                mFramesPerPacket: formatID == kAudioFormatMPEG4AAC
                    ? 1024 : 1,
                mBytesPerFrame: formatID == kAudioFormatLinearPCM
                    ? channels * 4 : 0,
                mChannelsPerFrame: channels,
                mBitsPerChannel: formatID == kAudioFormatLinearPCM
                    ? 32 : 0,
                mReserved: 0
            )

            // AAC pass-through requires AudioSpecificConfig as magic
            // cookie. Without it AVAssetWriterInput.append() silently
            // returns false for every sample buffer.
            let cookie = Self.aacMagicCookie(
                sampleRate: sampleRate, channels: channels)

            var desc: CMAudioFormatDescription?
            let result: OSStatus
            if formatID == kAudioFormatMPEG4AAC {
                result = cookie.withUnsafeBytes { ptr in
                    CMAudioFormatDescriptionCreate(
                        allocator: kCFAllocatorDefault,
                        asbd: &asbd,
                        layoutSize: 0,
                        layout: nil,
                        magicCookieSize: cookie.count,
                        magicCookie: ptr.baseAddress,
                        extensions: nil,
                        formatDescriptionOut: &desc
                    )
                }
            } else {
                result = CMAudioFormatDescriptionCreate(
                    allocator: kCFAllocatorDefault,
                    asbd: &asbd,
                    layoutSize: 0,
                    layout: nil,
                    magicCookieSize: 0,
                    magicCookie: nil,
                    extensions: nil,
                    formatDescriptionOut: &desc
                )
            }
            if result == noErr {
                audioFormatDescription = desc
            }
            return desc
        #else
            return nil
        #endif
    }

    /// Builds a minimal AAC AudioSpecificConfig (ISO 14496-3).
    ///
    /// Layout: audioObjectType(5) + samplingFrequencyIndex(4) +
    ///         channelConfiguration(4) + frameLengthFlag(1) +
    ///         dependsOnCoreCoder(1) + extensionFlag(1) = 16 bits.
    private static func aacMagicCookie(
        sampleRate: Double, channels: UInt32
    ) -> Data {
        let freqIndex: UInt8 = switch Int(sampleRate) {
        case 96_000: 0
        case 88_200: 1
        case 64_000: 2
        case 48_000: 3
        case 44_100: 4
        case 32_000: 5
        case 24_000: 6
        case 22_050: 7
        case 16_000: 8
        case 12_000: 9
        case 11_025: 10
        case 8_000: 11
        case 7_350: 12
        default: 4  // fallback to 44100
        }

        let objectType: UInt8 = 2  // AAC-LC
        let channelConfig = UInt8(min(channels, 7))

        // Pack into 2 bytes:
        // byte1 = objectType(5 bits) | freqIndex(top 3 of 4 bits)
        // byte2 = freqIndex(bottom 1 bit) | channelConfig(4) | padding(3)
        let byte1 = (objectType << 3) | (freqIndex >> 1)
        let byte2 = (freqIndex << 7) | (channelConfig << 3)
        return Data([byte1, byte2])
    }

    private func createPixelBuffer(
        from data: Data,
        width: Int,
        height: Int,
        adaptor: AVAssetWriterInputPixelBufferAdaptor
    ) -> CVPixelBuffer? {
        guard let pool = adaptor.pixelBufferPool else { return nil }

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
        guard let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer)
        else { return nil }

        let dstBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let srcBytesPerRow = width * 4

        data.withUnsafeBytes { ptr in
            guard let src = ptr.baseAddress else { return }
            if dstBytesPerRow == srcBytesPerRow {
                let count = min(
                    data.count, height * dstBytesPerRow)
                baseAddress.copyMemory(
                    from: src, byteCount: count)
            } else {
                for row in 0..<height {
                    (baseAddress + row * dstBytesPerRow).copyMemory(
                        from: src + row * srcBytesPerRow,
                        byteCount: srcBytesPerRow)
                }
            }
        }

        return buffer
    }
}
