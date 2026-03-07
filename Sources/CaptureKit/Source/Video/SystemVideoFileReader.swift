// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

@preconcurrency import AVFoundation
import Foundation

/// Real video file reader using AVAssetReader.
///
/// Actor isolation protects the non-Sendable AVAssetReader.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor SystemVideoFileReader: VideoFileReaderProviding {

    func open(url: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    func readFrames(
        from url: URL,
        outputFormat: VideoSourceConfiguration,
        startTime: TimeInterval,
        endTime: TimeInterval?,
        playbackRate: Double,
        loop: Bool
    ) async throws -> AsyncStream<CapturedVideoSample> {
        let asset = AVURLAsset(url: url)

        return AsyncStream { continuation in
            let task = Task {
                var shouldLoop = loop

                repeat {
                    do {
                        try await Self.readOnce(
                            asset: asset,
                            outputFormat: outputFormat,
                            startTime: startTime,
                            endTime: endTime,
                            playbackRate: playbackRate,
                            continuation: continuation
                        )
                    } catch {
                        continuation.finish()
                        return
                    }

                    if !loop { shouldLoop = false }
                } while shouldLoop && !Task.isCancelled

                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func stop() async {}

    // MARK: - Private Helpers

    private static func readOnce(
        asset: AVURLAsset,
        outputFormat: VideoSourceConfiguration,
        startTime: TimeInterval,
        endTime: TimeInterval?,
        playbackRate: Double,
        continuation: AsyncStream<CapturedVideoSample>.Continuation
    ) async throws {
        guard
            let videoTrack =
                try await asset
                .loadTracks(withMediaType: .video)
                .first
        else {
            continuation.finish()
            return
        }

        let reader = try AVAssetReader(asset: asset)
        let output = makeTrackOutput(track: videoTrack)
        reader.add(output)

        let start = CMTime(
            seconds: startTime, preferredTimescale: 600)
        let end: CMTime
        if let endTime {
            end = CMTime(
                seconds: endTime, preferredTimescale: 600)
        } else {
            end = try await asset.load(.duration)
        }
        reader.timeRange = CMTimeRange(start: start, end: end)

        guard reader.startReading() else {
            continuation.finish()
            return
        }

        try await drainReader(
            reader: reader,
            output: output,
            outputFormat: outputFormat,
            playbackRate: playbackRate,
            continuation: continuation
        )

        reader.cancelReading()
    }

    private static func makeTrackOutput(
        track: AVAssetTrack
    ) -> AVAssetReaderTrackOutput {
        let outputSettings: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_32BGRA
        ]
        return AVAssetReaderTrackOutput(
            track: track,
            outputSettings: outputSettings
        )
    }

    private static func drainReader(
        reader: AVAssetReader,
        output: AVAssetReaderTrackOutput,
        outputFormat: VideoSourceConfiguration,
        playbackRate: Double,
        continuation: AsyncStream<CapturedVideoSample>.Continuation
    ) async throws {
        while reader.status == .reading, !Task.isCancelled {
            guard
                let sampleBuffer = output.copyNextSampleBuffer()
            else { break }

            if let sample = extractSample(
                from: sampleBuffer,
                outputFormat: outputFormat)
            {
                continuation.yield(sample)
            }

            if playbackRate > 0 {
                let frameDuration =
                    1.0
                    / outputFormat.frameRate.value / playbackRate
                try? await Task.sleep(for: .seconds(frameDuration))
            }
        }
    }

    private static func extractSample(
        from sampleBuffer: CMSampleBuffer,
        outputFormat: VideoSourceConfiguration
    ) -> CapturedVideoSample? {
        guard
            let pixelBuffer = CMSampleBufferGetImageBuffer(
                sampleBuffer)
        else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard
            let baseAddress = CVPixelBufferGetBaseAddress(
                pixelBuffer)
        else { return nil }

        let data = Data(
            bytes: baseAddress, count: bytesPerRow * height)
        let pts = CMSampleBufferGetPresentationTimeStamp(
            sampleBuffer)

        let format = VideoFormat(
            resolution: .custom(width: width, height: height),
            frameRate: outputFormat.frameRate,
            pixelFormat: .bgra,
            colorSpace: outputFormat.colorSpace,
            dynamicRange: outputFormat.dynamicRange
        )

        return CapturedVideoSample(
            data: data,
            timestamp: CMTimeGetSeconds(pts),
            format: format,
            isKeyFrame: true
        )
    }
}
