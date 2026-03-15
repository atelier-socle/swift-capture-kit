// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CapturePreset Professional Factory Methods")
struct CapturePresetProfessionalTests {

    // MARK: - Radio / Web Radio

    @Test("radioLive returns AAC radio configuration with default bitrate")
    func radioLiveDefaultBitrate() {
        let config = CapturePreset.radioLive()
        #expect(config.name == "Radio Live 128k")
        #expect(config.category == .radio)
        #expect(config.audioCodec == .aac)
        #expect(config.audioBitrate == 128_000)
        #expect(config.audioSampleRate == .rate48000)
        #expect(config.audioChannelCount == 2)
        #expect(config.isAudioOnly)
    }

    @Test("radioLive accepts custom bitrate")
    func radioLiveCustomBitrate() {
        let config = CapturePreset.radioLive(bitrate: 256_000)
        #expect(config.name == "Radio Live 256k")
        #expect(config.audioBitrate == 256_000)
    }

    @Test("webRadioMP3 returns MP3 macOS-only configuration")
    func webRadioMP3DefaultBitrate() {
        let config = CapturePreset.webRadioMP3()
        #expect(config.name == "Web Radio MP3 128k")
        #expect(config.category == .radio)
        #expect(config.audioCodec == .mp3)
        #expect(config.audioBitrate == 128_000)
        #expect(config.audioSampleRate == .rate44100)
        #expect(config.audioChannelCount == 2)
        #expect(config.isMacOSOnly)
        #expect(config.isAudioOnly)
    }

    @Test("webRadioMP3 accepts custom bitrate")
    func webRadioMP3CustomBitrate() {
        let config = CapturePreset.webRadioMP3(bitrate: 320_000)
        #expect(config.name == "Web Radio MP3 320k")
        #expect(config.audioBitrate == 320_000)
    }

    @Test("webRadioOpus returns Opus configuration")
    func webRadioOpusDefaultBitrate() {
        let config = CapturePreset.webRadioOpus()
        #expect(config.name == "Web Radio Opus 64k")
        #expect(config.category == .radio)
        #expect(config.audioCodec == .opus)
        #expect(config.audioBitrate == 64_000)
        #expect(config.audioSampleRate == .rate48000)
        #expect(config.audioChannelCount == 2)
        #expect(config.isAudioOnly)
    }

    @Test("webRadioOpus accepts custom bitrate")
    func webRadioOpusCustomBitrate() {
        let config = CapturePreset.webRadioOpus(bitrate: 128_000)
        #expect(config.name == "Web Radio Opus 128k")
        #expect(config.audioBitrate == 128_000)
    }

    // MARK: - Professional / Broadcast

    @Test("broadcastHD returns HEVC 1080p60 broadcast configuration")
    func broadcastHDConfiguration() {
        let config = CapturePreset.broadcastHD()
        #expect(config.name == "Broadcast HD")
        #expect(config.category == .broadcast)
        #expect(config.audioCodec == .aac)
        #expect(config.audioBitrate == 256_000)
        #expect(config.videoCodec == .hevc)
        #expect(config.videoBitrate == 8_000_000)
        #expect(config.videoResolution == .p1080)
        #expect(config.videoFrameRate == .fps60)
        #expect(!config.isAudioOnly)
        #expect(!config.isVideoOnly)
    }

    @Test("broadcast4K returns HEVC 4K HDR configuration")
    func broadcast4KConfiguration() {
        let config = CapturePreset.broadcast4K()
        #expect(config.name == "Broadcast 4K HDR")
        #expect(config.category == .broadcast)
        #expect(config.audioCodec == .aac)
        #expect(config.audioBitrate == 320_000)
        #expect(config.videoCodec == .hevc)
        #expect(config.videoBitrate == 25_000_000)
        #expect(config.videoResolution == .uhd4K)
        #expect(config.videoFrameRate == .fps30)
    }

    @Test("proResRecording returns ProRes with PCM audio")
    func proResRecordingDefaultProfile() {
        let config = CapturePreset.proResRecording()
        #expect(config.category == .broadcast)
        #expect(config.audioCodec == .pcm)
        #expect(config.audioSampleRate == .rate48000)
        #expect(config.videoCodec == .prores)
        #expect(config.videoResolution == .uhd4K)
        #expect(config.minimumHardware == "Apple Silicon M1+")
    }

    // MARK: - Spatial / Immersive

    @Test("spatialVideo returns MV-HEVC spatial configuration")
    func spatialVideoConfiguration() {
        let config = CapturePreset.spatialVideo()
        #expect(config.name == "Spatial Video")
        #expect(config.category == .spatial)
        #expect(config.audioCodec == .aac)
        #expect(config.videoCodec == .mvHevc)
        #expect(config.videoBitrate == 25_000_000)
        #expect(config.videoResolution == .spatialVideo)
        #expect(config.minimumHardware == "Apple Silicon M1+ or visionOS")
    }

    @Test("dolbyAtmos returns 12-channel immersive configuration")
    func dolbyAtmosConfiguration() {
        let config = CapturePreset.dolbyAtmos()
        #expect(config.name == "Dolby Atmos")
        #expect(config.category == .spatial)
        #expect(config.audioCodec == .aac)
        #expect(config.audioBitrate == 512_000)
        #expect(config.audioChannelCount == 12)
        #expect(config.videoCodec == .hevc)
        #expect(config.videoBitrate == 25_000_000)
        #expect(config.minimumHardware == "Apple Silicon M1+")
    }
}
