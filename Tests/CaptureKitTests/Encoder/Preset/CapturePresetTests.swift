// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CapturePreset")
struct CapturePresetTests {

    // MARK: - Streaming

    @Test("twitch default is 720p30")
    func twitchDefault() {
        let config = CapturePreset.twitch()
        #expect(config.videoResolution == .p720)
        #expect(config.videoFrameRate == .fps30)
    }

    @Test("twitch 1080p has higher bitrate than 720p")
    func twitchHigherBitrateAt1080p() {
        let hd = CapturePreset.twitch(resolution: .p1080)
        let sd = CapturePreset.twitch()
        #expect((hd.videoBitrate ?? 0) > (sd.videoBitrate ?? 0))
    }

    @Test("twitch uses H264 codec")
    func twitchUsesH264() {
        let config = CapturePreset.twitch()
        #expect(config.videoCodec == .h264)
    }

    @Test("youtube default is 1080p60")
    func youtubeDefault() {
        let config = CapturePreset.youtube()
        #expect(config.videoResolution == .p1080)
        #expect(config.videoFrameRate == .fps60)
    }

    @Test("youtube uses H264 codec")
    func youtubeUsesH264() {
        let config = CapturePreset.youtube()
        #expect(config.videoCodec == .h264)
    }

    @Test("facebook default is 720p")
    func facebookDefault() {
        let config = CapturePreset.facebook()
        #expect(config.videoResolution == .p720)
    }

    @Test("instagram is 720p30")
    func instagramResolutionAndFrameRate() {
        let config = CapturePreset.instagram()
        #expect(config.videoResolution == .p720)
        #expect(config.videoFrameRate == .fps30)
    }

    @Test("tiktok uses vertical resolution")
    func tiktokVerticalResolution() {
        let config = CapturePreset.tiktok()
        #expect(config.videoResolution == .vertical1080)
    }

    // MARK: - Podcast

    @Test("podcastAudio is audio-only")
    func podcastAudioIsAudioOnly() {
        let config = CapturePreset.podcastAudio()
        #expect(config.isAudioOnly == true)
    }

    @Test("podcastAudio default is stereo 128k")
    func podcastAudioDefaultStereo128k() {
        let config = CapturePreset.podcastAudio()
        #expect(config.audioChannelCount == 2)
        #expect(config.audioBitrate == 128_000)
    }

    @Test("podcastAudioHQ has 256k bitrate")
    func podcastAudioHQBitrate() {
        let config = CapturePreset.podcastAudioHQ()
        #expect(config.audioBitrate == 256_000)
    }

    @Test("podcastVideo includes video codec")
    func podcastVideoHasVideoCodec() {
        let config = CapturePreset.podcastVideo()
        #expect(config.videoCodec != nil)
    }

    @Test("podcastLossless uses FLAC")
    func podcastLosslessUsesFlac() {
        let config = CapturePreset.podcastLossless()
        #expect(config.audioCodec == .flac)
    }

    // MARK: - Radio

    @Test("radioLive is audio-only")
    func radioLiveIsAudioOnly() {
        let config = CapturePreset.radioLive()
        #expect(config.isAudioOnly == true)
    }

    @Test("webRadioMP3 uses MP3 codec")
    func webRadioMP3UsesMP3() {
        let config = CapturePreset.webRadioMP3()
        #expect(config.audioCodec == .mp3)
    }

    @Test("webRadioMP3 is macOS only")
    func webRadioMP3IsMacOSOnly() {
        let config = CapturePreset.webRadioMP3()
        #expect(config.isMacOSOnly == true)
    }

    @Test("webRadioOpus uses Opus codec")
    func webRadioOpusUsesOpus() {
        let config = CapturePreset.webRadioOpus()
        #expect(config.audioCodec == .opus)
    }

    // MARK: - Professional

    @Test("broadcastHD uses HEVC")
    func broadcastHDUsesHEVC() {
        let config = CapturePreset.broadcastHD()
        #expect(config.videoCodec == .hevc)
    }

    @Test("broadcast4K has 25 Mbps bitrate")
    func broadcast4KBitrate() {
        let config = CapturePreset.broadcast4K()
        #expect(config.videoBitrate == 25_000_000)
    }

    @Test("proResRecording uses ProRes codec")
    func proResRecordingUsesProRes() {
        let config = CapturePreset.proResRecording()
        #expect(config.videoCodec == .prores)
    }

    @Test("proResRecording requires M1+")
    func proResRecordingMinimumHardware() {
        let config = CapturePreset.proResRecording()
        #expect(config.minimumHardware != nil)
    }

    // MARK: - Spatial

    @Test("spatialVideo uses MV-HEVC")
    func spatialVideoUsesMVHEVC() {
        let config = CapturePreset.spatialVideo()
        #expect(config.videoCodec == .mvHevc)
    }

    @Test("spatialVideo resolution is spatialVideo")
    func spatialVideoResolution() {
        let config = CapturePreset.spatialVideo()
        #expect(config.videoResolution == .spatialVideo)
    }

    @Test("dolbyAtmos has 12 audio channels")
    func dolbyAtmosChannelCount() {
        let config = CapturePreset.dolbyAtmos()
        #expect(config.audioChannelCount == 12)
    }

    // MARK: - Screen Recording

    @Test("screenRecording uses H264")
    func screenRecordingUsesH264() {
        let config = CapturePreset.screenRecording()
        #expect(config.videoCodec == .h264)
    }

    @Test("screenRecording4K uses HEVC")
    func screenRecording4KUsesHEVC() {
        let config = CapturePreset.screenRecording4K()
        #expect(config.videoCodec == .hevc)
    }

    // MARK: - Low Bandwidth

    @Test("lowBandwidth has less than 1 Mbps total bitrate")
    func lowBandwidthTotalBitrate() {
        let config = CapturePreset.lowBandwidth()
        let total = (config.audioBitrate ?? 0) + (config.videoBitrate ?? 0)
        #expect(total < 1_000_000)
    }

    @Test("voiceOnly is audio-only")
    func voiceOnlyIsAudioOnly() {
        let config = CapturePreset.voiceOnly()
        #expect(config.isAudioOnly == true)
    }

    @Test("voiceOnly is mono")
    func voiceOnlyIsMono() {
        let config = CapturePreset.voiceOnly()
        #expect(config.audioChannelCount == 1)
    }

    // MARK: - Archive

    @Test("archiveLossless uses ALAC audio")
    func archiveLosslessUsesALAC() {
        let config = CapturePreset.archiveLossless()
        #expect(config.audioCodec == .alac)
    }

    @Test("archive4K uses FLAC audio")
    func archive4KUsesFlac() {
        let config = CapturePreset.archive4K()
        #expect(config.audioCodec == .flac)
    }

    @Test("archive4K has high video bitrate")
    func archive4KHighVideoBitrate() {
        let config = CapturePreset.archive4K()
        #expect((config.videoBitrate ?? 0) >= 50_000_000)
    }
}
