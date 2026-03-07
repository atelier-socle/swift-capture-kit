// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// A resolved capture configuration from a preset.
///
/// Contains all the parameters needed to configure a CaptureSession:
/// audio source config, video source config, audio codec,
/// video codec, bitrates, and platform requirements.
public struct CapturePresetConfiguration: Sendable, Equatable {
    /// Human-readable preset name.
    public let name: String

    /// Category for grouping presets.
    public let category: PresetCategory

    /// Audio source configuration (nil = no audio).
    public let audioSourceConfiguration: AudioSourceConfiguration?

    /// Video source configuration (nil = no video).
    public let videoSourceConfiguration: VideoSourceConfiguration?

    /// Audio codec to use.
    public let audioCodec: AudioCodec?

    /// Audio encoder bitrate in bits per second.
    public let audioBitrate: Int?

    /// Audio sample rate.
    public let audioSampleRate: SampleRate?

    /// Audio channel count.
    public let audioChannelCount: Int?

    /// Video codec to use.
    public let videoCodec: VideoCodec?

    /// Video encoder bitrate in bits per second.
    public let videoBitrate: Int?

    /// Video resolution.
    public let videoResolution: VideoResolution?

    /// Video frame rate.
    public let videoFrameRate: FrameRate?

    /// Whether this preset is audio-only (no video).
    public var isAudioOnly: Bool { videoCodec == nil }

    /// Whether this preset is video-only (no audio).
    public var isVideoOnly: Bool { audioCodec == nil }

    /// Minimum hardware requirement (nil = any Apple device).
    public let minimumHardware: String?

    /// Whether this preset is macOS only (e.g., MP3 encoding).
    public let isMacOSOnly: Bool

    /// Creates a capture preset configuration.
    ///
    /// - Parameters:
    ///   - name: Human-readable preset name.
    ///   - category: Category for grouping presets.
    ///   - audioSourceConfiguration: Audio source configuration.
    ///   - videoSourceConfiguration: Video source configuration.
    ///   - audioCodec: Audio codec to use.
    ///   - audioBitrate: Audio bitrate in bits per second.
    ///   - audioSampleRate: Audio sample rate.
    ///   - audioChannelCount: Audio channel count.
    ///   - videoCodec: Video codec to use.
    ///   - videoBitrate: Video bitrate in bits per second.
    ///   - videoResolution: Video resolution.
    ///   - videoFrameRate: Video frame rate.
    ///   - minimumHardware: Minimum hardware requirement.
    ///   - isMacOSOnly: Whether this preset is macOS only.
    public init(
        name: String,
        category: PresetCategory,
        audioSourceConfiguration: AudioSourceConfiguration? = nil,
        videoSourceConfiguration: VideoSourceConfiguration? = nil,
        audioCodec: AudioCodec? = nil,
        audioBitrate: Int? = nil,
        audioSampleRate: SampleRate? = nil,
        audioChannelCount: Int? = nil,
        videoCodec: VideoCodec? = nil,
        videoBitrate: Int? = nil,
        videoResolution: VideoResolution? = nil,
        videoFrameRate: FrameRate? = nil,
        minimumHardware: String? = nil,
        isMacOSOnly: Bool = false
    ) {
        self.name = name
        self.category = category
        self.audioSourceConfiguration = audioSourceConfiguration
        self.videoSourceConfiguration = videoSourceConfiguration
        self.audioCodec = audioCodec
        self.audioBitrate = audioBitrate
        self.audioSampleRate = audioSampleRate
        self.audioChannelCount = audioChannelCount
        self.videoCodec = videoCodec
        self.videoBitrate = videoBitrate
        self.videoResolution = videoResolution
        self.videoFrameRate = videoFrameRate
        self.minimumHardware = minimumHardware
        self.isMacOSOnly = isMacOSOnly
    }
}

/// Category for grouping capture presets.
public enum PresetCategory: String, Sendable, CaseIterable {
    /// Live streaming presets (Twitch, YouTube, Facebook, etc.).
    case streaming
    /// Podcast recording presets.
    case podcast
    /// Web radio / internet radio presets.
    case radio
    /// Professional broadcast presets.
    case broadcast
    /// Spatial and immersive content presets.
    case spatial
    /// Screen recording presets.
    case screenRecording
    /// Low bandwidth / VoIP presets.
    case lowBandwidth
    /// Archival / maximum quality presets.
    case archive
}
