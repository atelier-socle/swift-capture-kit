// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

@preconcurrency import AVFoundation
import CoreVideo
import Foundation

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

    var bytesWritten: Int64 { _bytesWritten }

    func prepare(
        url: URL,
        container: FileContainer,
        audioFormat: AudioFormat?,
        videoFormat: VideoFormat?
    ) async throws {
        let fileType = avFileType(for: container)
        let assetWriter = try AVAssetWriter(
            outputURL: url, fileType: fileType)

        if let audioFormat {
            let settings = audioOutputSettings(for: audioFormat)
            let input = AVAssetWriterInput(
                mediaType: .audio, outputSettings: settings)
            input.expectsMediaDataInRealTime = true
            if assetWriter.canAdd(input) {
                assetWriter.add(input)
                self.audioInput = input
            }
        }

        if let videoFormat {
            let settings = videoOutputSettings(for: videoFormat)
            let input = AVAssetWriterInput(
                mediaType: .video, outputSettings: settings)
            input.expectsMediaDataInRealTime = true
            if assetWriter.canAdd(input) {
                assetWriter.add(input)
                self.videoInput = input
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
                self.pixelBufferAdaptor =
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
    }

    func writeAudio(
        _ data: Data,
        codec: AudioCodec,
        timestamp: TimeInterval,
        duration: TimeInterval
    ) async throws {
        guard let audioInput, audioInput.isReadyForMoreMediaData
        else { return }

        let cmTime = CMTime(
            seconds: timestamp, preferredTimescale: 48_000)
        if let sampleBuffer = createAudioSampleBuffer(
            data: data, timestamp: cmTime, duration: duration)
        {
            audioInput.append(sampleBuffer)
            _bytesWritten += Int64(data.count)
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
        duration: TimeInterval
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
        CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: nil,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
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
