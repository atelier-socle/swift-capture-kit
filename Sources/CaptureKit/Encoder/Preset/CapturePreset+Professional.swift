// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

extension CapturePreset {

    // MARK: - Radio / Web Radio

    /// Live radio preset.
    ///
    /// - Parameters:
    ///   - bitrate: Audio bitrate in bps (default 128,000).
    /// - Returns: Audio-only AAC configuration for radio streaming.
    public static func radioLive(
        bitrate: Int = 128_000
    ) -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Radio Live \(bitrate / 1000)k",
            category: .radio,
            audioSourceConfiguration: .default,
            audioCodec: .aac,
            audioBitrate: bitrate,
            audioSampleRate: .rate48000,
            audioChannelCount: 2
        )
    }

    /// Web radio MP3 preset (macOS only for encoding).
    ///
    /// - Parameters:
    ///   - bitrate: MP3 bitrate in bps (default 128,000).
    /// - Returns: MP3 stereo configuration.
    public static func webRadioMP3(
        bitrate: Int = 128_000
    ) -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Web Radio MP3 \(bitrate / 1000)k",
            category: .radio,
            audioSourceConfiguration: .default,
            audioCodec: .mp3,
            audioBitrate: bitrate,
            audioSampleRate: .rate44100,
            audioChannelCount: 2,
            isMacOSOnly: true
        )
    }

    /// Web radio Opus preset (lowest latency).
    ///
    /// - Parameters:
    ///   - bitrate: Opus bitrate in bps (default 64,000).
    /// - Returns: Opus stereo configuration.
    public static func webRadioOpus(
        bitrate: Int = 64_000
    ) -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Web Radio Opus \(bitrate / 1000)k",
            category: .radio,
            audioSourceConfiguration: .default,
            audioCodec: .opus,
            audioBitrate: bitrate,
            audioSampleRate: .rate48000,
            audioChannelCount: 2
        )
    }

    // MARK: - Professional / Broadcast

    /// Broadcast HD 1080p preset.
    ///
    /// - Returns: HEVC Main10, AAC 256k, 8 Mbps.
    public static func broadcastHD() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Broadcast HD",
            category: .broadcast,
            audioSourceConfiguration: .broadcast,
            videoSourceConfiguration: .broadcast1080p60,
            audioCodec: .aac,
            audioBitrate: 256_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .hevc,
            videoBitrate: 8_000_000,
            videoResolution: .p1080,
            videoFrameRate: .fps60
        )
    }

    /// Broadcast 4K HDR preset.
    ///
    /// - Returns: HEVC Main10 HDR10, AAC 320k, 25 Mbps.
    public static func broadcast4K() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Broadcast 4K HDR",
            category: .broadcast,
            audioSourceConfiguration: .broadcast,
            videoSourceConfiguration: .pro4K,
            audioCodec: .aac,
            audioBitrate: 320_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .hevc,
            videoBitrate: 25_000_000,
            videoResolution: .uhd4K,
            videoFrameRate: .fps30
        )
    }

    /// ProRes recording preset.
    ///
    /// - Parameters:
    ///   - profile: ProRes profile (default .hq).
    /// - Returns: ProRes + PCM 48k 24-bit configuration.
    public static func proResRecording(
        profile: ProResProfile = .hq
    ) -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "ProRes \(profile.rawValue.uppercased())",
            category: .broadcast,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: .pro4K,
            audioCodec: .pcm,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .prores,
            videoResolution: .uhd4K,
            videoFrameRate: .fps30,
            minimumHardware: "Apple Silicon M1+"
        )
    }

    // MARK: - Spatial / Immersive

    /// Spatial video preset for Apple Vision Pro.
    ///
    /// - Returns: MV-HEVC + spatial audio configuration.
    public static func spatialVideo() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Spatial Video",
            category: .spatial,
            audioSourceConfiguration: .spatialAudio,
            videoSourceConfiguration: .spatialVideo,
            audioCodec: .aac,
            audioBitrate: 256_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .mvHevc,
            videoBitrate: 25_000_000,
            videoResolution: .spatialVideo,
            videoFrameRate: .fps30,
            minimumHardware: "Apple Silicon M1+ or visionOS"
        )
    }

    /// Dolby Atmos capture preset.
    ///
    /// - Returns: 7.1.4 audio + HEVC HDR10 video.
    public static func dolbyAtmos() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Dolby Atmos",
            category: .spatial,
            audioSourceConfiguration: AudioSourceConfiguration(
                sampleRate: .rate48000, channelCount: 12,
                bitDepth: .float32, preferredBufferDuration: 0.02
            ),
            videoSourceConfiguration: .pro4K,
            audioCodec: .aac,
            audioBitrate: 512_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 12,
            videoCodec: .hevc,
            videoBitrate: 25_000_000,
            videoResolution: .uhd4K,
            videoFrameRate: .fps30,
            minimumHardware: "Apple Silicon M1+"
        )
    }
}
