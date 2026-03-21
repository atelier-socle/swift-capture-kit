// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Presets Showcase", .tags(.showcase), .timeLimit(.minutes(1)))
struct PresetsShowcaseTests {

    // MARK: - PresetCategory

    @Test("PresetCategory enumerates all categories")
    func presetCategories() {
        let categories = PresetCategory.allCases
        #expect(categories.contains(.streaming))
        #expect(categories.contains(.podcast))
        #expect(categories.contains(.radio))
        #expect(categories.contains(.broadcast))
        #expect(categories.contains(.spatial))
        #expect(categories.contains(.screenRecording))
        #expect(categories.contains(.lowBandwidth))
        #expect(categories.contains(.archive))
    }

    // MARK: - Streaming Presets

    @Test("Twitch preset uses H.264 720p30")
    func twitchPreset() {
        let preset = CapturePreset.twitch()
        #expect(preset.name.lowercased().contains("twitch"))
        #expect(preset.category == .streaming)
        #expect(preset.videoCodec == .h264)
        #expect(preset.videoResolution == .p720)
        #expect(preset.videoFrameRate == .fps30)
        #expect(preset.audioCodec == .aac)
        #expect(preset.isAudioOnly == false)
    }

    @Test("YouTube preset uses 1080p60")
    func youtubePreset() {
        let preset = CapturePreset.youtube()
        #expect(preset.category == .streaming)
        #expect(preset.videoResolution == .p1080)
        #expect(preset.videoFrameRate == .fps60)
        #expect(preset.audioCodec == .aac)
    }

    @Test("Facebook preset uses 720p30")
    func facebookPreset() {
        let preset = CapturePreset.facebook()
        #expect(preset.category == .streaming)
        #expect(preset.videoResolution == .p720)
        #expect(preset.videoFrameRate == .fps30)
    }

    @Test("Instagram preset is configured")
    func instagramPreset() {
        let preset = CapturePreset.instagram()
        #expect(preset.category == .streaming)
        #expect(preset.videoCodec != nil)
        #expect(preset.audioCodec != nil)
    }

    @Test("TikTok preset is configured")
    func tiktokPreset() {
        let preset = CapturePreset.tiktok()
        #expect(preset.category == .streaming)
        #expect(preset.videoCodec != nil)
        #expect(preset.audioCodec != nil)
    }

    // MARK: - Podcast Presets

    @Test("Podcast audio preset is audio-only AAC")
    func podcastAudioPreset() {
        let preset = CapturePreset.podcastAudio()
        #expect(preset.category == .podcast)
        #expect(preset.audioCodec == .aac)
        #expect(preset.isAudioOnly == true)
        #expect(preset.audioBitrate == 128_000)
    }

    @Test("Podcast audio HQ preset uses higher quality")
    func podcastAudioHQPreset() {
        let preset = CapturePreset.podcastAudioHQ()
        #expect(preset.category == .podcast)
        #expect(preset.isAudioOnly == true)
    }

    @Test("Podcast video preset has both audio and video")
    func podcastVideoPreset() {
        let preset = CapturePreset.podcastVideo()
        #expect(preset.category == .podcast)
        #expect(preset.audioCodec != nil)
        #expect(preset.videoCodec != nil)
        #expect(preset.isAudioOnly == false)
        #expect(preset.isVideoOnly == false)
    }

    @Test("Podcast lossless preset uses lossless codec")
    func podcastLosslessPreset() {
        let preset = CapturePreset.podcastLossless()
        #expect(preset.category == .podcast)
        #expect(preset.isAudioOnly == true)
        #expect(preset.audioCodec == .alac || preset.audioCodec == .flac)
    }

    // MARK: - Radio Presets

    @Test("Radio live preset is audio-only AAC")
    func radioLivePreset() {
        let preset = CapturePreset.radioLive()
        #expect(preset.category == .radio)
        #expect(preset.audioCodec == .aac)
        #expect(preset.isAudioOnly == true)
    }

    @Test("Web radio MP3 preset uses MP3")
    func webRadioMP3Preset() {
        let preset = CapturePreset.webRadioMP3()
        #expect(preset.category == .radio)
        #expect(preset.audioCodec == .mp3)
        #expect(preset.isAudioOnly == true)
    }

    @Test("Web radio Opus preset uses Opus")
    func webRadioOpusPreset() {
        let preset = CapturePreset.webRadioOpus()
        #expect(preset.category == .radio)
        #expect(preset.audioCodec == .opus)
        #expect(preset.isAudioOnly == true)
    }

    // MARK: - Broadcast Presets

    @Test("Broadcast HD preset uses 1080p HEVC")
    func broadcastHDPreset() {
        let preset = CapturePreset.broadcastHD()
        #expect(preset.category == .broadcast)
        #expect(preset.videoCodec != nil)
        #expect(preset.videoResolution == .p1080)
    }

    @Test("Broadcast 4K preset uses UHD resolution")
    func broadcast4KPreset() {
        let preset = CapturePreset.broadcast4K()
        #expect(preset.category == .broadcast)
        #expect(preset.videoResolution == .uhd4K)
    }

    @Test("ProRes recording preset uses ProRes codec")
    func proResRecordingPreset() {
        let preset = CapturePreset.proResRecording()
        #expect(preset.category == .broadcast)
        #expect(preset.videoCodec == .prores)
    }

    // MARK: - Spatial Presets

    @Test("Spatial video preset is configured")
    func spatialVideoPreset() {
        let preset = CapturePreset.spatialVideo()
        #expect(preset.category == .spatial)
        #expect(preset.videoCodec != nil)
    }

    @Test("Dolby Atmos preset is audio-focused")
    func dolbyAtmosPreset() {
        let preset = CapturePreset.dolbyAtmos()
        #expect(preset.category == .spatial)
        #expect(preset.audioCodec != nil)
    }

    // MARK: - Screen Recording Presets

    @Test("Screen recording preset uses 30fps")
    func screenRecordingPreset() {
        let preset = CapturePreset.screenRecording()
        #expect(preset.category == .screenRecording)
        #expect(preset.videoFrameRate == .fps30)
    }

    @Test("Screen recording 4K preset uses UHD")
    func screenRecording4KPreset() {
        let preset = CapturePreset.screenRecording4K()
        #expect(preset.category == .screenRecording)
        #expect(preset.videoResolution == .uhd4K)
    }

    // MARK: - Low Bandwidth Presets

    @Test("Low bandwidth preset has reduced settings")
    func lowBandwidthPreset() {
        let preset = CapturePreset.lowBandwidth()
        #expect(preset.category == .lowBandwidth)
        #expect(preset.videoCodec != nil)
    }

    @Test("Voice-only preset is audio-only")
    func voiceOnlyPreset() {
        let preset = CapturePreset.voiceOnly()
        #expect(preset.category == .lowBandwidth)
        #expect(preset.isAudioOnly == true)
    }

    // MARK: - Archive Presets

    @Test("Archive lossless preset uses lossless codecs")
    func archiveLosslessPreset() {
        let preset = CapturePreset.archiveLossless()
        #expect(preset.category == .archive)
    }

    @Test("Archive 4K preset uses UHD resolution")
    func archive4KPreset() {
        let preset = CapturePreset.archive4K()
        #expect(preset.category == .archive)
        #expect(preset.videoResolution == .uhd4K)
    }

    // MARK: - CapturePresetConfiguration Properties

    @Test("CapturePresetConfiguration isAudioOnly and isVideoOnly")
    func presetConfigFlags() {
        let audioOnly = CapturePresetConfiguration(
            name: "Test",
            category: .podcast,
            audioCodec: .aac,
            audioBitrate: 128_000
        )
        #expect(audioOnly.isAudioOnly == true)
        #expect(audioOnly.isVideoOnly == false)

        let videoOnly = CapturePresetConfiguration(
            name: "Test",
            category: .streaming,
            videoCodec: .h264,
            videoBitrate: 2_500_000
        )
        #expect(videoOnly.isAudioOnly == false)
        #expect(videoOnly.isVideoOnly == true)
    }

    @Test("Twitch preset with custom resolution override")
    func twitchCustomResolution() {
        let preset = CapturePreset.twitch(
            resolution: .p1080, frameRate: .fps60
        )
        #expect(preset.videoResolution == .p1080)
        #expect(preset.videoFrameRate == .fps60)
    }
}
