// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

@preconcurrency import AVFoundation
import Foundation

/// Real audio file reader using AVAssetReader.
///
/// Actor isolation protects the non-Sendable AVAssetReader.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor SystemAudioFileReader: AudioFileReaderProviding {

    func open(url: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    func readSamples(
        _ request: FileReadRequest
    ) async throws -> AsyncStream<CapturedAudioSample> {
        let asset = AVURLAsset(url: request.url)

        return AsyncStream { continuation in
            let task = Task {
                var shouldLoop = request.loop

                repeat {
                    do {
                        try await Self.readOnce(
                            asset: asset,
                            request: request,
                            continuation: continuation
                        )
                    } catch {
                        continuation.finish()
                        return
                    }

                    if !request.loop { shouldLoop = false }
                } while shouldLoop && !Task.isCancelled

                continuation.finish()
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func stop() async {
        // Cancellation handled via Task.isCancelled
    }

    private static func readOnce(
        asset: AVURLAsset,
        request: FileReadRequest,
        continuation: AsyncStream<CapturedAudioSample>.Continuation
    ) async throws {
        let outputFormat = request.outputFormat
        let startTime = request.startTime
        let endTime = request.endTime
        let playbackRate = request.playbackRate
        guard
            let audioTrack =
                try await asset
                .loadTracks(withMediaType: .audio)
                .first
        else {
            continuation.finish()
            return
        }

        let reader = try AVAssetReader(asset: asset)
        let output = makeTrackOutput(
            track: audioTrack,
            outputFormat: outputFormat
        )
        reader.add(output)

        let start = CMTime(
            seconds: startTime,
            preferredTimescale: 48000)
        let end: CMTime
        if let endTime {
            end = CMTime(
                seconds: endTime,
                preferredTimescale: 48000)
        } else {
            end = try await asset.load(.duration)
        }
        reader.timeRange = CMTimeRange(
            start: start, end: end)

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
        track: AVAssetTrack,
        outputFormat: AudioSourceConfiguration
    ) -> AVAssetReaderTrackOutput {
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: outputFormat.sampleRate.rawValue,
            AVNumberOfChannelsKey: outputFormat.channelCount,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: false
        ]
        return AVAssetReaderTrackOutput(
            track: track,
            outputSettings: outputSettings
        )
    }

    private static func drainReader(
        reader: AVAssetReader,
        output: AVAssetReaderTrackOutput,
        outputFormat: AudioSourceConfiguration,
        playbackRate: Double,
        continuation: AsyncStream<CapturedAudioSample>.Continuation
    ) async throws {
        let format = AudioFormat(
            sampleRate: outputFormat.sampleRate,
            channelCount: outputFormat.channelCount,
            channelLayout: outputFormat.channelCount == 1
                ? .mono : .stereo,
            bitDepth: .float32,
            isInterleaved: true
        )

        while reader.status == .reading, !Task.isCancelled {
            guard
                let sampleBuffer = output.copyNextSampleBuffer()
            else { break }

            if let sample = extractSample(
                from: sampleBuffer, format: format)
            {
                continuation.yield(sample)
            }

            if playbackRate > 0 {
                let bufferDuration =
                    outputFormat.preferredBufferDuration
                    / playbackRate
                try? await Task.sleep(
                    for: .seconds(bufferDuration))
            }
        }
    }

    private static func extractSample(
        from sampleBuffer: CMSampleBuffer,
        format: AudioFormat
    ) -> CapturedAudioSample? {
        guard
            let dataBuffer = CMSampleBufferGetDataBuffer(
                sampleBuffer)
        else { return nil }

        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(
            dataBuffer, atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer)

        guard let dataPointer else { return nil }

        let data = Data(bytes: dataPointer, count: length)
        let pts = CMSampleBufferGetPresentationTimeStamp(
            sampleBuffer)

        return CapturedAudioSample(
            data: data,
            timestamp: CMTimeGetSeconds(pts),
            format: format
        )
    }
}
