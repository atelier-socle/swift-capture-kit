// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Industry-grade capture presets combining audio source config, video source config,
/// audio encoder, and video encoder into a single ready-to-use configuration.
///
/// Presets are factory methods that return a `CapturePresetConfiguration` with
/// all parameters pre-configured for common capture scenarios.
///
/// ```swift
/// // One-liner streaming setup
/// let config = CapturePreset.twitch(resolution: .p1080, frameRate: .fps30)
/// let session = CaptureSession.configured(with: config)
///
/// // Podcast recording
/// let config = CapturePreset.podcastAudio(bitrate: 256_000)
/// ```
public enum CapturePreset {

    // MARK: - Streaming

    /// Twitch streaming preset.
    ///
    /// - Parameters:
    ///   - resolution: Video resolution (default .p720).
    ///   - frameRate: Frame rate (default .fps30).
    /// - Returns: Configuration with H.264 Main, AAC 128k, appropriate bitrate.
    public static func twitch(
        resolution: VideoResolution = .p720,
        frameRate: FrameRate = .fps30
    ) -> CapturePresetConfiguration {
        let videoBitrate: Int
        switch resolution {
        case .p720: videoBitrate = 2_500_000
        case .p1080: videoBitrate = 4_500_000
        default: videoBitrate = 3_000_000
        }

        return CapturePresetConfiguration(
            name: "Twitch \(resolution)",
            category: .streaming,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: VideoSourceConfiguration(
                resolution: resolution, frameRate: frameRate,
                pixelFormat: .nv12, colorSpace: .bt709,
                dynamicRange: .sdr, stabilization: .off,
                focusMode: .continuousAutoFocus,
                exposureMode: .continuousAutoExposure,
                whiteBalanceMode: .continuousAutoWhiteBalance
            ),
            audioCodec: .aac,
            audioBitrate: 128_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .h264,
            videoBitrate: videoBitrate,
            videoResolution: resolution,
            videoFrameRate: frameRate
        )
    }

    /// YouTube streaming preset.
    ///
    /// - Parameters:
    ///   - resolution: Video resolution (default .p1080).
    ///   - frameRate: Frame rate (default .fps60).
    /// - Returns: Configuration with H.264 High, AAC 128k, appropriate bitrate.
    public static func youtube(
        resolution: VideoResolution = .p1080,
        frameRate: FrameRate = .fps60
    ) -> CapturePresetConfiguration {
        let videoBitrate: Int
        switch resolution {
        case .p720: videoBitrate = 4_000_000
        case .p1080: videoBitrate = 8_000_000
        case .uhd4K: videoBitrate = 35_000_000
        default: videoBitrate = 6_000_000
        }

        return CapturePresetConfiguration(
            name: "YouTube \(resolution)",
            category: .streaming,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: VideoSourceConfiguration(
                resolution: resolution, frameRate: frameRate,
                pixelFormat: .nv12, colorSpace: .bt709,
                dynamicRange: .sdr, stabilization: .off,
                focusMode: .continuousAutoFocus,
                exposureMode: .continuousAutoExposure,
                whiteBalanceMode: .continuousAutoWhiteBalance
            ),
            audioCodec: .aac,
            audioBitrate: 128_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .h264,
            videoBitrate: videoBitrate,
            videoResolution: resolution,
            videoFrameRate: frameRate
        )
    }

    /// Facebook Live preset.
    ///
    /// - Parameters:
    ///   - resolution: Video resolution (default .p720).
    ///   - frameRate: Frame rate (default .fps30).
    /// - Returns: Configuration with H.264 Main, AAC 128k.
    public static func facebook(
        resolution: VideoResolution = .p720,
        frameRate: FrameRate = .fps30
    ) -> CapturePresetConfiguration {
        let videoBitrate: Int
        switch resolution {
        case .p720: videoBitrate = 3_000_000
        case .p1080: videoBitrate = 6_000_000
        default: videoBitrate = 3_000_000
        }

        return CapturePresetConfiguration(
            name: "Facebook Live \(resolution)",
            category: .streaming,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: VideoSourceConfiguration(
                resolution: resolution, frameRate: frameRate,
                pixelFormat: .nv12, colorSpace: .bt709,
                dynamicRange: .sdr, stabilization: .off,
                focusMode: .continuousAutoFocus,
                exposureMode: .continuousAutoExposure,
                whiteBalanceMode: .continuousAutoWhiteBalance
            ),
            audioCodec: .aac,
            audioBitrate: 128_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .h264,
            videoBitrate: videoBitrate,
            videoResolution: resolution,
            videoFrameRate: frameRate
        )
    }

    /// Instagram Live preset.
    ///
    /// - Returns: Configuration with 720p30, H.264 Baseline, AAC 96k.
    public static func instagram() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Instagram Live",
            category: .streaming,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: .broadcast720p,
            audioCodec: .aac,
            audioBitrate: 96_000,
            audioSampleRate: .rate44100,
            audioChannelCount: 2,
            videoCodec: .h264,
            videoBitrate: 2_000_000,
            videoResolution: .p720,
            videoFrameRate: .fps30
        )
    }

    /// TikTok Live preset (vertical).
    ///
    /// - Returns: Configuration with vertical 1080p, H.264 High, AAC 128k.
    public static func tiktok() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "TikTok Live",
            category: .streaming,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: VideoSourceConfiguration(
                resolution: .vertical1080, frameRate: .fps30,
                pixelFormat: .nv12, colorSpace: .bt709,
                dynamicRange: .sdr, stabilization: .off,
                focusMode: .continuousAutoFocus,
                exposureMode: .continuousAutoExposure,
                whiteBalanceMode: .continuousAutoWhiteBalance
            ),
            audioCodec: .aac,
            audioBitrate: 128_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .h264,
            videoBitrate: 4_000_000,
            videoResolution: .vertical1080,
            videoFrameRate: .fps30
        )
    }

    // MARK: - Podcast

    /// Podcast audio-only preset.
    ///
    /// - Parameters:
    ///   - channels: Channel count (default 2 for stereo).
    ///   - bitrate: Audio bitrate in bps (default 128,000).
    /// - Returns: Audio-only configuration with AAC-LC.
    public static func podcastAudio(
        channels: Int = 2,
        bitrate: Int = 128_000
    ) -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Podcast Audio \(bitrate / 1000)k",
            category: .podcast,
            audioSourceConfiguration: .default,
            audioCodec: .aac,
            audioBitrate: bitrate,
            audioSampleRate: .rate48000,
            audioChannelCount: channels
        )
    }

    /// Podcast high-quality audio preset.
    ///
    /// - Returns: AAC-LC 256 kbps stereo 48 kHz.
    public static func podcastAudioHQ() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Podcast Audio HQ",
            category: .podcast,
            audioSourceConfiguration: .default,
            audioCodec: .aac,
            audioBitrate: 256_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2
        )
    }

    /// Podcast with video preset.
    ///
    /// - Parameters:
    ///   - resolution: Video resolution (default .p720).
    /// - Returns: Configuration with H.264 Main + AAC 128k.
    public static func podcastVideo(
        resolution: VideoResolution = .p720
    ) -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Podcast Video \(resolution)",
            category: .podcast,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: .broadcast720p,
            audioCodec: .aac,
            audioBitrate: 128_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .h264,
            videoBitrate: 2_500_000,
            videoResolution: resolution,
            videoFrameRate: .fps30
        )
    }

    /// Podcast lossless audio preset.
    ///
    /// - Returns: FLAC stereo 48 kHz.
    public static func podcastLossless() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Podcast Lossless",
            category: .podcast,
            audioSourceConfiguration: .default,
            audioCodec: .flac,
            audioSampleRate: .rate48000,
            audioChannelCount: 2
        )
    }
}
