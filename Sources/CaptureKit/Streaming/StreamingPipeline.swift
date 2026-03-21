// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Unified capture → encode → send pipeline.
///
/// `StreamingPipeline` captures from audio and/or video sources, encodes the
/// raw buffers, and delivers `MediaPacket` values to a `StreamingTransport`.
///
/// Three modes are supported:
/// - `.audioOnly` — single audio source + encoder.
/// - `.videoOnly` — single video source + encoder.
/// - `.muxed`     — both audio and video interleaved through a common
///                  `AsyncStream<MediaPacket>` channel.
///
/// In `.muxed` mode the pipeline waits for the first video keyframe, extracts
/// parameter sets (SPS/PPS for H.264, VPS/SPS/PPS for HEVC), and sends codec
/// configuration via `StreamingTransport.sendConfiguration` **before** the
/// consumer loop begins delivering packets.
///
/// All packets (audio and video) are timestamped using a shared monotonic
/// wall clock (`ContinuousClock`) so both tracks share a single timeline
/// starting at zero. The epoch is captured lazily when the first packet is
/// produced, so gated audio in muxed mode starts at t≈0.
public actor StreamingPipeline {

    // MARK: - Mode

    /// Pipeline operating mode.
    public enum Mode: Sendable {
        /// Audio capture and encoding only.
        case audioOnly(source: any AudioSource, encoder: any AudioEncoderProtocol)

        /// Video capture and encoding only.
        case videoOnly(source: any VideoSource, encoder: any VideoEncoderProtocol)

        /// Muxed audio + video through a common packet channel.
        case muxed(
            videoSource: any VideoSource,
            videoEncoder: any VideoEncoderProtocol,
            audioSource: any AudioSource,
            audioEncoder: any AudioEncoderProtocol
        )
    }

    // MARK: - State

    private enum State {
        case idle
        case streaming
        case stopped
    }

    // MARK: - Properties

    private let mode: Mode
    private let transport: any StreamingTransport

    private var state: State = .idle
    private var producerTasks: [Task<Void, Never>] = []
    private var consumerTask: Task<Void, any Error>?
    private var muxContinuation: AsyncStream<MediaPacket>.Continuation?
    private var startTime: Date?

    // Monotonic epoch captured lazily on the first call to
    // pipelineTimestamp. This ensures gated audio in muxed mode
    // starts at t≈0 instead of accumulating dead time while
    // waiting for the first video frame.
    private var pipelineEpoch: ContinuousClock.Instant?

    // Tracks how many producers are still active so the mux continuation
    // is only finished once all producers complete.
    private var activeProducerCount = 0

    // In muxed mode, audio packets are dropped until the first video
    // packet arrives so both tracks start together.
    private var firstVideoReceived = false

    // Stats accumulators
    private var _bytesSent: Int64 = 0
    private var _videoFrameCount: Int64 = 0
    private var _audioBufferCount: Int64 = 0
    private var _videoFramesDropped: Int64 = 0
    private var _audioBuffersDropped: Int64 = 0

    // MARK: - Init

    /// Create a new streaming pipeline.
    ///
    /// - Parameters:
    ///   - mode: The operating mode (audioOnly, videoOnly, or muxed).
    ///   - transport: The transport implementation that delivers packets to
    ///     the remote endpoint.
    public init(mode: Mode, transport: any StreamingTransport) {
        self.mode = mode
        self.transport = transport
    }

    deinit {
        for task in producerTasks {
            task.cancel()
        }
        consumerTask?.cancel()
        muxContinuation?.finish()
    }

    // MARK: - Public API

    /// Current pipeline statistics snapshot.
    public var stats: StreamingStats {
        let duration: TimeInterval
        if let start = startTime {
            duration = Date().timeIntervalSince(start)
        } else {
            duration = 0
        }
        return StreamingStats(
            bytesSent: _bytesSent,
            duration: duration,
            videoFPS: duration > 0
                ? Double(_videoFrameCount) / duration : 0,
            audioSampleRate: duration > 0
                ? Double(_audioBufferCount) / duration : 0,
            videoFramesDropped: _videoFramesDropped,
            audioBuffersDropped: _audioBuffersDropped,
            isStreaming: state == .streaming
        )
    }

    /// Start the pipeline: connect transport, start capture, begin encoding
    /// and sending.
    public func start() async throws {
        guard state == .idle else { return }

        try await transport.connect()
        state = .streaming
        startTime = Date()
        pipelineEpoch = nil
        firstVideoReceived = false

        switch mode {
        case .audioOnly(let source, let encoder):
            try await startAudioOnly(source: source, encoder: encoder)

        case .videoOnly(let source, let encoder):
            try await startVideoOnly(source: source, encoder: encoder)

        case .muxed(
            let videoSource, let videoEncoder,
            let audioSource, let audioEncoder):
            try await startMuxed(
                videoSource: videoSource, videoEncoder: videoEncoder,
                audioSource: audioSource, audioEncoder: audioEncoder
            )
        }
    }

    /// Stop the pipeline: stop sources, cancel producers, finish mux
    /// continuation, cancel consumer, disconnect transport.
    public func stop() async {
        guard state == .streaming else { return }
        state = .stopped

        // Stop sources first so their streams finish, unblocking
        // any producer suspended on `for await`.
        switch mode {
        case .audioOnly(let source, _):
            await source.stopCapture()
        case .videoOnly(let source, _):
            await source.stopCapture()
        case .muxed(let videoSource, _, let audioSource, _):
            await audioSource.stopCapture()
            await videoSource.stopCapture()
        }

        for task in producerTasks {
            task.cancel()
        }
        producerTasks.removeAll()
        activeProducerCount = 0

        muxContinuation?.finish()
        muxContinuation = nil

        consumerTask?.cancel()
        consumerTask = nil

        try? await transport.disconnect()
    }

    // MARK: - Audio Only

    private func startAudioOnly(
        source: any AudioSource,
        encoder: any AudioEncoderProtocol
    ) async throws {
        let audioStream = try await source.startCapture()
        let transport = self.transport

        let task = Task { @concurrent [weak self] in
            var localBytes: Int64 = 0
            var localCount: Int64 = 0
            for await buffer in audioStream {
                guard !Task.isCancelled else { break }
                do {
                    let encoded = try await encoder.encode(buffer)
                    guard !encoded.data.isEmpty else { continue }
                    let ts = await self?.ensureEpochAndTimestamp() ?? 0
                    let packet = MediaPacket.audio(encoded)
                        .withTimestamp(ts)
                    try await transport.send(packet)
                    localBytes += Int64(encoded.data.count)
                    localCount += 1
                    if localCount % 30 == 0 {
                        await self?.flushAudioStats(
                            bytes: localBytes, count: localCount)
                        localBytes = 0
                        localCount = 0
                    }
                } catch {
                    if Task.isCancelled { break }
                }
            }
            if localCount > 0 {
                await self?.flushAudioStats(
                    bytes: localBytes, count: localCount)
            }
        }
        producerTasks.append(task)
    }

    // MARK: - Video Only

    private func startVideoOnly(
        source: any VideoSource,
        encoder: any VideoEncoderProtocol
    ) async throws {
        let videoStream = try await source.startCapture()
        let transport = self.transport

        let task = Task { @concurrent [weak self] in
            var sentConfig = false
            var localBytes: Int64 = 0
            var localCount: Int64 = 0
            for await frame in videoStream {
                guard !Task.isCancelled else { break }
                do {
                    let encoded = try await encoder.encode(frame)
                    if !sentConfig && encoded.isKeyFrame {
                        await self?.sendVideoConfiguration(encoder: encoder)
                        sentConfig = true
                    }
                    let ts = await self?.ensureEpochAndTimestamp() ?? 0
                    let packet = MediaPacket.video(encoded)
                        .withTimestamp(ts)
                    try await transport.send(packet)
                    localBytes += Int64(encoded.data.count)
                    localCount += 1
                    if localCount % 30 == 0 {
                        await self?.flushVideoStats(
                            bytes: localBytes, count: localCount)
                        localBytes = 0
                        localCount = 0
                    }
                } catch {
                    if Task.isCancelled { break }
                }
            }
            if localCount > 0 {
                await self?.flushVideoStats(
                    bytes: localBytes, count: localCount)
            }
        }
        producerTasks.append(task)
    }

    // MARK: - Muxed

    private func startMuxed(
        videoSource: any VideoSource,
        videoEncoder: any VideoEncoderProtocol,
        audioSource: any AudioSource,
        audioEncoder: any AudioEncoderProtocol
    ) async throws {
        let (muxStream, continuation) = AsyncStream<MediaPacket>.makeStream()
        muxContinuation = continuation
        activeProducerCount = 2

        let audioStream = try await audioSource.startCapture()
        producerTasks.append(
            startMuxedAudioProducer(
                audioStream: audioStream, encoder: audioEncoder,
                continuation: continuation))

        let videoStream = try await videoSource.startCapture()
        producerTasks.append(
            startMuxedVideoProducer(
                videoStream: videoStream, encoder: videoEncoder,
                continuation: continuation))

        startMuxedConsumer(muxStream: muxStream)
    }

    private func startMuxedAudioProducer(
        audioStream: AsyncStream<AudioBuffer>,
        encoder: any AudioEncoderProtocol,
        continuation: AsyncStream<MediaPacket>.Continuation
    ) -> Task<Void, Never> {
        Task { @concurrent [weak self] in
            for await buffer in audioStream {
                guard !Task.isCancelled else { break }
                guard await self?.firstVideoReceived == true else { continue }
                do {
                    let encoded = try await encoder.encode(buffer)
                    guard !encoded.data.isEmpty else { continue }
                    let ts = await self?.ensureEpochAndTimestamp() ?? 0
                    continuation.yield(.audio(encoded.withTimestamp(ts)))
                } catch {
                    if Task.isCancelled { break }
                }
            }
            await self?.producerDidFinish()
        }
    }

    private func startMuxedVideoProducer(
        videoStream: AsyncStream<VideoFrame>,
        encoder: any VideoEncoderProtocol,
        continuation: AsyncStream<MediaPacket>.Continuation
    ) -> Task<Void, Never> {
        Task { @concurrent [weak self] in
            var sentConfig = false
            for await frame in videoStream {
                guard !Task.isCancelled else { break }
                do {
                    let encoded = try await encoder.encode(frame)
                    if !sentConfig && encoded.isKeyFrame {
                        await self?.sendVideoConfiguration(encoder: encoder)
                        sentConfig = true
                    }
                    if await self?.firstVideoReceived == false {
                        await self?.setFirstVideoReceived()
                    }
                    let ts = await self?.ensureEpochAndTimestamp() ?? 0
                    continuation.yield(.video(encoded.withTimestamp(ts)))
                } catch {
                    if Task.isCancelled { break }
                }
            }
            await self?.producerDidFinish()
        }
    }

    private func startMuxedConsumer(
        muxStream: AsyncStream<MediaPacket>
    ) {
        let transport = self.transport
        consumerTask = Task { @concurrent [weak self] in
            var localAudioBytes: Int64 = 0
            var localAudioCount: Int64 = 0
            var localVideoBytes: Int64 = 0
            var localVideoCount: Int64 = 0
            var totalCount: Int64 = 0
            for await packet in muxStream {
                guard !Task.isCancelled else { break }
                do {
                    try await transport.send(packet)
                    switch packet {
                    case .video(let frame):
                        localVideoBytes += Int64(frame.data.count)
                        localVideoCount += 1
                    case .audio(let buffer):
                        localAudioBytes += Int64(buffer.data.count)
                        localAudioCount += 1
                    }
                    totalCount += 1
                    if totalCount % 30 == 0 {
                        await self?.flushMuxStats(
                            audioBytes: localAudioBytes,
                            audioCount: localAudioCount,
                            videoBytes: localVideoBytes,
                            videoCount: localVideoCount)
                        localAudioBytes = 0
                        localAudioCount = 0
                        localVideoBytes = 0
                        localVideoCount = 0
                    }
                } catch {
                    if Task.isCancelled { break }
                }
            }
            if localAudioCount > 0 || localVideoCount > 0 {
                await self?.flushMuxStats(
                    audioBytes: localAudioBytes,
                    audioCount: localAudioCount,
                    videoBytes: localVideoBytes,
                    videoCount: localVideoCount)
            }
        }
    }

}

// MARK: - Internal Helpers

extension StreamingPipeline {

    /// Called by each mux producer when it finishes. Finishes the
    /// continuation only after ALL producers are done so the consumer
    /// loop processes every packet.
    private func producerDidFinish() {
        activeProducerCount -= 1
        if activeProducerCount <= 0 {
            muxContinuation?.finish()
            muxContinuation = nil
        }
    }

    private func sendVideoConfiguration(
        encoder: any VideoEncoderProtocol
    ) async {
        do {
            if let h264 = encoder as? H264Encoder,
                let params = await h264.parameterSets
            {
                let configData = params.sps + params.pps
                try await transport.sendConfiguration(
                    .video(codec: .h264, parameterSets: configData))
            } else if let hevc = encoder as? HEVCEncoder,
                let params = await hevc.parameterSets
            {
                let configData = params.vps + params.sps + params.pps
                try await transport.sendConfiguration(
                    .video(codec: .hevc, parameterSets: configData))
            }
        } catch {
            // Configuration send failure is non-fatal; the transport
            // may still accept raw packets.
        }
    }

    private func setFirstVideoReceived() {
        firstVideoReceived = true
    }

    /// Lazily captures the pipeline epoch on first call, then returns
    /// the elapsed time. This ensures gated tracks start at t≈0.
    func ensureEpochAndTimestamp() -> TimeInterval {
        let epoch =
            pipelineEpoch
            ?? {
                let now = ContinuousClock.Instant.now
                pipelineEpoch = now
                return now
            }()
        let elapsed = ContinuousClock.now - epoch
        return Double(elapsed.components.seconds)
            + Double(elapsed.components.attoseconds) * 1e-18
    }

    private func flushAudioStats(bytes: Int64, count: Int64) {
        _bytesSent += bytes
        _audioBufferCount += count
    }

    private func flushVideoStats(bytes: Int64, count: Int64) {
        _bytesSent += bytes
        _videoFrameCount += count
    }

    private func flushMuxStats(
        audioBytes: Int64, audioCount: Int64,
        videoBytes: Int64, videoCount: Int64
    ) {
        _bytesSent += audioBytes + videoBytes
        _audioBufferCount += audioCount
        _videoFrameCount += videoCount
    }
}
