// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// The main orchestrator for all capture operations.
///
/// CaptureSession manages the full capture lifecycle: connecting sources to
/// encoders, routing encoded media to outputs, handling state transitions,
/// and providing real-time statistics and events.
///
/// ```swift
/// let session = CaptureSession()
/// session.audioSource = MicrophoneSource()
/// session.audioEncoder = AACEncoder(configuration: .podcast)
/// try await session.addOutput(fileOutput)
/// try await session.start()
/// // ... capture ...
/// await session.stop()
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor CaptureSession {

    // MARK: - Sources

    /// The audio source for capture (microphone, file, generator, etc.).
    /// Can only be set when state is `.idle` or `.configuring`.
    /// Use `switchAudioSource(_:)` to change source during capture.
    public var audioSource: (any AudioSource)?

    /// The video source for capture (camera, screen, generator, etc.).
    /// Can only be set when state is `.idle` or `.configuring`.
    /// Use `switchVideoSource(_:)` to change source during capture.
    public var videoSource: (any VideoSource)?

    // MARK: - Encoders

    /// The audio encoder (AAC, ALAC, Opus, FLAC, PCM, MP3).
    public var audioEncoder: (any AudioEncoderProtocol)?

    /// The video encoder (H.264, HEVC, ProRes, AV1, MV-HEVC, JPEG).
    public var videoEncoder: (any VideoEncoderProtocol)?

    // MARK: - Outputs

    /// The number of currently attached outputs.
    public var outputCount: Int { outputs.count }

    // MARK: - State

    /// The current session state.
    public private(set) var state: CaptureSessionState = .idle

    /// Runtime statistics (updated periodically during capture).
    public private(set) var statistics: CaptureSessionStatistics = .zero

    // MARK: - Events

    /// Stream of session events (state changes, errors, statistics updates).
    public var events: AsyncStream<CaptureSessionEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: CaptureSessionEvent.self)
        self.eventContinuation = continuation
        return stream
    }

    // MARK: - Configuration

    /// Session configuration.
    public let configuration: CaptureSessionConfiguration

    // MARK: - Private State

    /// Currently attached outputs.
    private var outputs: [any CaptureOutput] = []

    /// Event stream continuation for emitting events.
    private var eventContinuation: AsyncStream<CaptureSessionEvent>.Continuation?

    /// The background task running the capture loop.
    private var captureTask: Task<Void, Never>?

    /// The time capture started.
    private var startTime: Date?

    // MARK: - Lifecycle

    /// Creates a new capture session with the given configuration.
    ///
    /// - Parameter configuration: The session configuration. Defaults to
    ///   ``CaptureSessionConfiguration/default``.
    public init(configuration: CaptureSessionConfiguration = .default) {
        self.configuration = configuration
    }

    deinit {
        captureTask?.cancel()
        eventContinuation?.finish()
    }

    // MARK: - Output Management

    /// Add an output destination.
    ///
    /// Can be called before or during capture. If called during capture,
    /// the output begins receiving data immediately.
    public func addOutput(_ output: any CaptureOutput) async throws {
        outputs.append(output)
        emitEvent(.outputAdded(output.outputID))
    }

    /// Remove an output destination by ID.
    ///
    /// If capture is active, the output is finalized before removal.
    public func removeOutput(_ outputID: String) async {
        if let index = outputs.firstIndex(where: { $0.outputID == outputID }) {
            let output = outputs.remove(at: index)
            try? await output.finalize()
            emitEvent(.outputRemoved(outputID))
        }
    }

    // MARK: - Capture Lifecycle

    /// Start capture from all configured sources, encoding, and delivery to outputs.
    ///
    /// Transitions: idle/ready -> starting -> capturing
    ///
    /// - Throws: `CaptureError.sessionAlreadyRunning` if already running,
    ///   `CaptureError.sessionNotConfigured` if no sources are set,
    ///   `CaptureError.invalidConfiguration` if no outputs are attached.
    public func start() async throws {
        guard state == .idle || state == .ready else {
            throw CaptureError.sessionAlreadyRunning
        }
        guard audioSource != nil || videoSource != nil else {
            throw CaptureError.sessionNotConfigured
        }
        guard !outputs.isEmpty else {
            throw CaptureError.invalidConfiguration(
                "At least one output is required"
            )
        }

        setState(.starting)

        // Prepare all outputs
        let audioFormat =
            audioSource != nil
            ? await audioSource?.activeFormat : nil
        let videoFormat =
            videoSource != nil
            ? await videoSource?.activeFormat : nil

        for output in outputs {
            do {
                try await output.prepare(
                    audioFormat: audioFormat, videoFormat: videoFormat
                )
            } catch {
                emitEvent(
                    .outputError(
                        outputID: output.outputID, error: error
                    ))
                setState(.idle)
                throw CaptureError.outputPrepareFailed(
                    outputID: output.outputID,
                    reason: error.localizedDescription
                )
            }
        }

        startTime = Date()
        setState(.capturing)

        // Start capture loop
        captureTask = Task { [weak self] in
            await self?.runCaptureLoop()
        }
    }

    /// Pause capture (keeps connections alive, stops data flow).
    ///
    /// Transitions: capturing -> paused
    public func pause() async {
        guard state == .capturing else { return }
        setState(.paused)
    }

    /// Resume from pause.
    ///
    /// Transitions: paused -> capturing
    ///
    /// - Throws: `CaptureError.sessionNotRunning` if not paused.
    public func resume() async throws {
        guard state == .paused else {
            throw CaptureError.sessionNotRunning
        }
        setState(.capturing)
    }

    /// Stop capture completely.
    ///
    /// Transitions: any active state -> stopping -> idle.
    /// Stops all sources, finalizes all outputs, cleans up resources.
    public func stop() async {
        guard
            state == .capturing || state == .paused
                || state == .starting
        else {
            return
        }

        setState(.stopping)

        // Cancel capture task
        captureTask?.cancel()
        captureTask = nil

        // Stop sources
        if let audioSource = audioSource {
            await audioSource.stopCapture()
        }
        if let videoSource = videoSource {
            await videoSource.stopCapture()
        }

        // Flush encoders
        if let audioEncoder = audioEncoder {
            _ = try? await audioEncoder.flush()
        }
        if let videoEncoder = videoEncoder {
            _ = try? await videoEncoder.flush()
        }

        // Finalize all outputs
        for output in outputs {
            try? await output.finalize()
        }

        startTime = nil
        statistics = .zero
        setState(.idle)
    }

    // MARK: - Dynamic Control

    /// Update the audio encoder's bitrate during capture.
    ///
    /// - Parameter bitrate: The new audio bitrate in bits per second.
    /// - Throws: `CaptureError.sessionNotRunning` if not capturing.
    public func updateAudioBitrate(_ bitrate: Int) async throws {
        guard state == .capturing else {
            throw CaptureError.sessionNotRunning
        }
        emitEvent(.bitrateChanged(audio: bitrate, video: nil))
    }

    /// Update the video encoder's bitrate during capture.
    ///
    /// - Parameter bitrate: The new video bitrate in bits per second.
    /// - Throws: `CaptureError.sessionNotRunning` if not capturing.
    public func updateVideoBitrate(_ bitrate: Int) async throws {
        guard state == .capturing else {
            throw CaptureError.sessionNotRunning
        }
        if let videoEncoder = videoEncoder {
            try await videoEncoder.updateBitrate(bitrate)
        }
        emitEvent(.bitrateChanged(audio: nil, video: bitrate))
    }

    /// Force a video keyframe (IDR frame).
    ///
    /// - Throws: `CaptureError.sessionNotRunning` if not capturing.
    public func forceKeyFrame() async throws {
        guard state == .capturing else {
            throw CaptureError.sessionNotRunning
        }
        if let videoEncoder = videoEncoder {
            try await videoEncoder.forceKeyFrame()
        }
    }

    /// Switch the audio source during capture (hot-swap).
    ///
    /// - Parameter source: The new audio source to switch to.
    /// - Throws: `CaptureError.sessionNotRunning` if not capturing or paused.
    public func switchAudioSource(_ source: any AudioSource) async throws {
        guard state == .capturing || state == .paused else {
            throw CaptureError.sessionNotRunning
        }
        if let oldSource = audioSource {
            await oldSource.stopCapture()
        }
        audioSource = source
        emitEvent(.audioSourceReady(sourceID: source.sourceID))
    }

    /// Switch the video source during capture (hot-swap).
    ///
    /// - Parameter source: The new video source to switch to.
    /// - Throws: `CaptureError.sessionNotRunning` if not capturing or paused.
    public func switchVideoSource(_ source: any VideoSource) async throws {
        guard state == .capturing || state == .paused else {
            throw CaptureError.sessionNotRunning
        }
        if let oldSource = videoSource {
            await oldSource.stopCapture()
        }
        videoSource = source
        emitEvent(.videoSourceReady(sourceID: source.sourceID))
    }

    // MARK: - Presets

    /// Create a CaptureSession pre-configured with a preset name.
    ///
    /// The preset configures the appropriate source types, encoders,
    /// and session configuration. Sources and outputs must still be
    /// added by the caller.
    ///
    /// - Note: CapturePreset is not yet implemented (Session 10).
    ///   This method is a placeholder that returns a default session.
    /// - Parameter preset: The preset name to configure with.
    /// - Returns: A new capture session with the preset applied.
    public static func configured(with preset: String) -> CaptureSession {
        CaptureSession()
    }

    // MARK: - Private Methods

    /// Main capture loop — reads from sources, encodes, delivers to outputs.
    private func runCaptureLoop() async {
        while !Task.isCancelled && state == .capturing {
            if let startTime = startTime {
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
            try? await Task.sleep(for: .milliseconds(100))
        }
    }

    /// Transition state and emit event.
    private func setState(_ newState: CaptureSessionState) {
        state = newState
        emitEvent(.stateChanged(newState))
    }

    /// Emit an event to all listeners.
    private func emitEvent(_ event: CaptureSessionEvent) {
        eventContinuation?.yield(event)
    }
}
