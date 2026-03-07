// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

@preconcurrency import AVFoundation
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
        var blockBuffer: CMBlockBuffer?
        let length = frame.data.count

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

        status = frame.data.withUnsafeBytes { rawBuffer in
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
            duration: .invalid,
            presentationTimeStamp: CMTime(
                seconds: frame.timestamp,
                preferredTimescale: 90_000),
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
}
