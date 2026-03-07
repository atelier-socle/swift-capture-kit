// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Audio monitoring output for hearing captured audio in real time.
///
/// Passes audio through to the system audio output device for monitoring
/// using AVAudioEngine. Does not record — purely for real-time monitoring
/// during capture.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor AudioPreviewOutput: CaptureOutput {
    /// A unique identifier for this output.
    public let outputID: String

    /// A human-readable display name for this output.
    public let displayName: String = "Audio Preview Output"

    /// The type of this output destination.
    public nonisolated let outputType: CaptureOutputType = .audioPreview

    /// The current lifecycle state of this output.
    public private(set) var state: CaptureOutputState = .idle

    /// Monitoring volume (0.0–1.0).
    public var volume: Float {
        didSet {
            let newVolume = volume
            Task { await playbackEngine?.setVolume(newVolume) }
        }
    }

    /// Whether monitoring is muted.
    public var isMuted: Bool {
        didSet {
            let muted = isMuted
            Task { await playbackEngine?.setMuted(muted) }
        }
    }

    /// Total audio buffers monitored.
    public private(set) var buffersMonitored: Int64 = 0

    /// The playback engine (DI — defaults to real AVAudioEngine).
    private var playbackEngine: (any AudioPlaybackProviding)?

    /// Creates a new audio preview output.
    ///
    /// - Parameter volume: The monitoring volume (0.0–1.0).
    public init(volume: Float = 1.0) {
        self.outputID = "audio-preview-\(UUID().uuidString.prefix(8))"
        self.volume = max(0.0, min(1.0, volume))
        self.isMuted = false
        #if canImport(AVFAudio)
            self.playbackEngine = SystemAudioPlaybackEngine()
        #endif
    }

    /// Creates a new audio preview output with an injected playback engine.
    ///
    /// - Parameters:
    ///   - volume: The monitoring volume.
    ///   - playbackEngine: The playback engine to use.
    init(
        volume: Float = 1.0,
        playbackEngine: any AudioPlaybackProviding
    ) {
        self.outputID = "audio-preview-\(UUID().uuidString.prefix(8))"
        self.volume = max(0.0, min(1.0, volume))
        self.isMuted = false
        self.playbackEngine = playbackEngine
    }

    /// Prepares the output to receive media data.
    ///
    /// - Parameters:
    ///   - audioFormat: The audio format to expect, or `nil` if no audio.
    ///   - videoFormat: The video format to expect, or `nil` if no video.
    public func prepare(
        audioFormat: AudioFormat?, videoFormat: VideoFormat?
    ) async throws {
        if let audioFormat {
            try await playbackEngine?.prepare(format: audioFormat)
        }
        state = .active
    }

    /// Delivers an encoded audio buffer to this output for monitoring.
    ///
    /// - Parameter buffer: The encoded audio buffer to monitor.
    public func receiveAudio(_ buffer: EncodedAudioBuffer) async throws {
        guard state == .active, !isMuted else { return }
        try await playbackEngine?.play(buffer.data)
        buffersMonitored += 1
    }

    /// Delivers an encoded video frame to this output.
    ///
    /// Video is ignored — audio preview is audio-only.
    ///
    /// - Parameter frame: The encoded video frame (ignored).
    public func receiveVideo(_ frame: EncodedVideoFrame) async throws {
        // Audio preview ignores video
    }

    /// Finalizes the output.
    public func finalize() async throws {
        await playbackEngine?.stop()
        state = .finalized
    }
}
