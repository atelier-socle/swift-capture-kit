// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

extension CapturePreset {

    // MARK: - Screen Recording

    /// Screen recording preset.
    ///
    /// - Parameters:
    ///   - frameRate: Frame rate (default .fps30).
    /// - Returns: Configuration appropriate for screen content.
    public static func screenRecording(
        frameRate: FrameRate = .fps30
    ) -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Screen Recording",
            category: .screenRecording,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: VideoSourceConfiguration(
                resolution: .p1080, frameRate: frameRate,
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
            videoBitrate: 5_000_000,
            videoResolution: .p1080,
            videoFrameRate: frameRate
        )
    }

    /// Screen recording 4K preset.
    ///
    /// - Returns: HEVC Main, system audio, 4K.
    public static func screenRecording4K() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Screen Recording 4K",
            category: .screenRecording,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: .pro4K,
            audioCodec: .aac,
            audioBitrate: 128_000,
            audioSampleRate: .rate48000,
            audioChannelCount: 2,
            videoCodec: .hevc,
            videoBitrate: 15_000_000,
            videoResolution: .uhd4K,
            videoFrameRate: .fps30
        )
    }

    /// Screen recording Retina preset.
    ///
    /// - Returns: H.264 High, 60fps, native retina resolution.
    public static func screenRecordingRetina() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Screen Recording Retina",
            category: .screenRecording,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: VideoSourceConfiguration(
                resolution: .uhd4K, frameRate: .fps60,
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
            videoBitrate: 20_000_000,
            videoResolution: .uhd4K,
            videoFrameRate: .fps60
        )
    }

    // MARK: - Low Bandwidth

    /// Low bandwidth preset.
    ///
    /// - Returns: VGA 15fps, H.264 Baseline, AAC 64k, ~500 kbps total.
    public static func lowBandwidth() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Low Bandwidth",
            category: .lowBandwidth,
            audioSourceConfiguration: .default,
            videoSourceConfiguration: VideoSourceConfiguration(
                resolution: .vga, frameRate: .fps15,
                pixelFormat: .nv12, colorSpace: .bt709,
                dynamicRange: .sdr, stabilization: .off,
                focusMode: .continuousAutoFocus,
                exposureMode: .continuousAutoExposure,
                whiteBalanceMode: .continuousAutoWhiteBalance
            ),
            audioCodec: .aac,
            audioBitrate: 64_000,
            audioSampleRate: .rate44100,
            audioChannelCount: 2,
            videoCodec: .h264,
            videoBitrate: 400_000,
            videoResolution: .vga,
            videoFrameRate: .fps15
        )
    }

    /// Voice-only preset (VoIP grade).
    ///
    /// - Returns: AAC 32k mono, no video.
    public static func voiceOnly() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Voice Only",
            category: .lowBandwidth,
            audioSourceConfiguration: .voiceChat,
            audioCodec: .aac,
            audioBitrate: 32_000,
            audioSampleRate: .rate16000,
            audioChannelCount: 1
        )
    }

    // MARK: - Archive

    /// Lossless archive preset.
    ///
    /// - Returns: HEVC lossless + ALAC maximum quality.
    public static func archiveLossless() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Archive Lossless",
            category: .archive,
            audioSourceConfiguration: .highResolution,
            videoSourceConfiguration: .pro4K,
            audioCodec: .alac,
            audioSampleRate: .rate96000,
            audioChannelCount: 2,
            videoCodec: .hevc,
            videoBitrate: 100_000_000,
            videoResolution: .uhd4K,
            videoFrameRate: .fps30
        )
    }

    /// 4K archive preset.
    ///
    /// - Returns: 4K30 HEVC 50 Mbps + FLAC 96 kHz.
    public static func archive4K() -> CapturePresetConfiguration {
        CapturePresetConfiguration(
            name: "Archive 4K",
            category: .archive,
            audioSourceConfiguration: .highResolution,
            videoSourceConfiguration: .pro4K,
            audioCodec: .flac,
            audioSampleRate: .rate96000,
            audioChannelCount: 2,
            videoCodec: .hevc,
            videoBitrate: 50_000_000,
            videoResolution: .uhd4K,
            videoFrameRate: .fps30
        )
    }
}
