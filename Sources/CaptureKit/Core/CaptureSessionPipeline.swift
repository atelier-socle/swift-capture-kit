// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension CaptureSession {

    /// Main capture loop — reads from sources, encodes, delivers to outputs.
    ///
    /// Starts audio and video source capture, reads from their AsyncStreams,
    /// encodes each buffer/frame through the configured encoders, and
    /// delivers encoded data to all attached outputs.
    func runCaptureLoop() async {
        await withTaskGroup(of: Void.self) { group in
            if let audioSource = self.audioSource {
                group.addTask { [weak self] in
                    await self?.runAudioPipeline(source: audioSource)
                }
            }

            if let videoSource = self.videoSource {
                group.addTask { [weak self] in
                    await self?.runVideoPipeline(source: videoSource)
                }
            }

            group.addTask { [weak self] in
                await self?.runStatisticsLoop()
            }
        }
    }

    private func runAudioPipeline(source: any AudioSource) async {
        do {
            let stream = try await source.startCapture()
            for await buffer in stream {
                guard !Task.isCancelled else { break }
                if state == .paused { continue }
                await processAudioBuffer(buffer)
            }
        } catch {
            emitEvent(
                .sourceError(sourceID: source.sourceID, error: error))
        }
    }

    private func runVideoPipeline(source: any VideoSource) async {
        do {
            let stream = try await source.startCapture()
            for await frame in stream {
                guard !Task.isCancelled else { break }
                if state == .paused { continue }
                await processVideoFrame(frame)
            }
        } catch {
            emitEvent(
                .sourceError(sourceID: source.sourceID, error: error))
        }
    }

    private func runStatisticsLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(250))
            updateStatistics()
        }
    }

    /// Process a single audio buffer through encoder and outputs.
    func processAudioBuffer(_ buffer: AudioBuffer) async {
        var encodedData = buffer.data
        var encodedCodec: AudioCodec = .pcm
        var audioBytesEncoded: Int64 = 0

        if let audioEncoder {
            do {
                let encoded = try await audioEncoder.encode(buffer)
                encodedData = encoded.data
                encodedCodec = encoded.codec
                audioBytesEncoded = Int64(encoded.data.count)
            } catch {
                emitEvent(.encoderError(codec: "encoder", error: error))
                return
            }
        }

        let encodedBuffer = EncodedAudioBuffer(
            data: encodedData,
            codec: encodedCodec,
            timestamp: buffer.timestamp,
            duration: buffer.duration,
            sequenceNumber: buffer.sequenceNumber
        )

        for output in outputs {
            try? await output.receiveAudio(encodedBuffer)
        }

        statistics = CaptureSessionStatistics(
            uptime: statistics.uptime,
            audioBuffersProcessed: statistics.audioBuffersProcessed + 1,
            videoFramesProcessed: statistics.videoFramesProcessed,
            videoFramesDropped: statistics.videoFramesDropped,
            audioBytesEncoded: statistics.audioBytesEncoded
                + audioBytesEncoded,
            videoBytesEncoded: statistics.videoBytesEncoded,
            currentAudioBitrate: statistics.currentAudioBitrate,
            currentVideoBitrate: statistics.currentVideoBitrate,
            currentFrameRate: statistics.currentFrameRate,
            cpuUsage: statistics.cpuUsage,
            memoryUsage: statistics.memoryUsage
        )
    }

    /// Process a single video frame through encoder and outputs.
    func processVideoFrame(_ frame: VideoFrame) async {
        var encodedData = frame.data
        var encodedCodec: VideoCodec = .h264
        var isKeyFrame = frame.isKeyFrame
        var videoBytesEncoded: Int64 = 0

        if let videoEncoder {
            do {
                let encoded = try await videoEncoder.encode(frame)
                encodedData = encoded.data
                encodedCodec = encoded.codec
                isKeyFrame = encoded.isKeyFrame
                videoBytesEncoded = Int64(encoded.data.count)
            } catch {
                emitEvent(.encoderError(codec: "encoder", error: error))
                return
            }
        }

        let encodedFrame = EncodedVideoFrame(
            data: encodedData,
            codec: encodedCodec,
            timestamp: frame.timestamp,
            isKeyFrame: isKeyFrame,
            sequenceNumber: frame.sequenceNumber
        )

        for output in outputs {
            try? await output.receiveVideo(encodedFrame)
        }

        statistics = CaptureSessionStatistics(
            uptime: statistics.uptime,
            audioBuffersProcessed: statistics.audioBuffersProcessed,
            videoFramesProcessed: statistics.videoFramesProcessed + 1,
            videoFramesDropped: statistics.videoFramesDropped,
            audioBytesEncoded: statistics.audioBytesEncoded,
            videoBytesEncoded: statistics.videoBytesEncoded
                + videoBytesEncoded,
            currentAudioBitrate: statistics.currentAudioBitrate,
            currentVideoBitrate: statistics.currentVideoBitrate,
            currentFrameRate: statistics.currentFrameRate,
            cpuUsage: statistics.cpuUsage,
            memoryUsage: statistics.memoryUsage
        )
    }

    /// Update uptime statistics.
    func updateStatistics() {
        guard let startTime else { return }
        statistics = CaptureSessionStatistics(
            uptime: Date().timeIntervalSince(startTime),
            audioBuffersProcessed: statistics.audioBuffersProcessed,
            videoFramesProcessed: statistics.videoFramesProcessed,
            videoFramesDropped: statistics.videoFramesDropped,
            audioBytesEncoded: statistics.audioBytesEncoded,
            videoBytesEncoded: statistics.videoBytesEncoded,
            currentAudioBitrate: statistics.currentAudioBitrate,
            currentVideoBitrate: statistics.currentVideoBitrate,
            currentFrameRate: statistics.currentFrameRate,
            cpuUsage: statistics.cpuUsage,
            memoryUsage: statistics.memoryUsage
        )
    }
}
