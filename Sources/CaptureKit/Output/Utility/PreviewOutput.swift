// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

@preconcurrency import AVFoundation
import CoreVideo
import Foundation

/// Video preview output for SwiftUI integration.
///
/// Receives video frames and makes them available for display
/// via an AVSampleBufferDisplayLayer. Use in SwiftUI by wrapping
/// the `displayLayer` in a UIViewRepresentable/NSViewRepresentable.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor PreviewOutput: CaptureOutput {
    /// A unique identifier for this output.
    public let outputID: String

    /// A human-readable display name for this output.
    public let displayName: String = "Preview Output"

    /// The type of this output destination.
    public nonisolated let outputType: CaptureOutputType = .preview

    /// The current lifecycle state of this output.
    public private(set) var state: CaptureOutputState = .idle

    /// The most recent video frame (for display).
    public private(set) var latestFrame: EncodedVideoFrame?

    /// Total frames received.
    public private(set) var framesReceived: Int64 = 0

    /// Whether to drop frames when the display can't keep up.
    public var dropFramesWhenBehind: Bool

    /// Video dimensions from prepare().
    private var videoWidth: Int = 0
    private var videoHeight: Int = 0

    /// The display layer for rendering video frames.
    ///
    /// Use in SwiftUI via UIViewRepresentable/NSViewRepresentable.
    /// The layer is created during `prepare()`.
    public private(set) var displayLayer: AVSampleBufferDisplayLayer?

    /// Creates a new preview output.
    ///
    /// - Parameter dropFramesWhenBehind: Whether to drop frames when behind.
    public init(dropFramesWhenBehind: Bool = true) {
        self.outputID = "preview-\(UUID().uuidString.prefix(8))"
        self.dropFramesWhenBehind = dropFramesWhenBehind
    }

    /// Prepares the output to receive media data.
    ///
    /// - Parameters:
    ///   - audioFormat: The audio format to expect, or `nil` if no audio.
    ///   - videoFormat: The video format to expect, or `nil` if no video.
    public func prepare(
        audioFormat: AudioFormat?, videoFormat: VideoFormat?
    ) async throws {
        let layer = AVSampleBufferDisplayLayer()
        layer.videoGravity = .resizeAspect
        self.displayLayer = layer
        if let videoFormat {
            self.videoWidth = videoFormat.resolution.width
            self.videoHeight = videoFormat.resolution.height
        }
        state = .active
    }

    /// Delivers an encoded audio buffer to this output.
    ///
    /// Audio is ignored — preview output is video-only.
    ///
    /// - Parameter buffer: The encoded audio buffer (ignored).
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        // Preview is video-only
    }

    /// Delivers an encoded video frame to this output.
    ///
    /// Enqueues the frame on the display layer for rendering.
    ///
    /// - Parameter frame: The encoded video frame to receive.
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        guard state == .active else { return }
        framesReceived += 1
        latestFrame = frame

        if let sampleBuffer = createSampleBuffer(from: frame),
            let layer = displayLayer
        {
            layer.enqueue(sampleBuffer)
        }
    }

    /// Finalizes the output, clearing the latest frame.
    public func finalize() async throws {
        displayLayer?.flushAndRemoveImage()
        displayLayer = nil
        latestFrame = nil
        state = .finalized
    }

    // MARK: - Private

    private func createSampleBuffer(
        from frame: EncodedVideoFrame
    ) -> CMSampleBuffer? {
        let width = videoWidth
        let height = videoHeight
        guard width > 0, height > 0 else { return nil }

        // Create CVPixelBuffer from raw frame data
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            width, height,
            kCVPixelFormatType_32BGRA,
            nil, &pixelBuffer)
        guard let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
            let dstBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            let srcBytesPerRow = width * 4
            frame.data.withUnsafeBytes { ptr in
                guard let src = ptr.baseAddress else { return }
                if dstBytesPerRow == srcBytesPerRow {
                    let count = min(
                        frame.data.count, height * dstBytesPerRow)
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
        }

        // Create format description from the pixel buffer
        var formatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescriptionOut: &formatDescription)
        guard let formatDesc = formatDescription else { return nil }

        var timing = CMSampleTimingInfo(
            duration: .invalid,
            presentationTimeStamp: CMTime(
                seconds: frame.timestamp,
                preferredTimescale: 90_000),
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            dataReady: true,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDesc,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer)
        return sampleBuffer
    }
}
