// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CapturePresetConfiguration", .timeLimit(.minutes(1)))
struct CapturePresetConfigurationTests {

    @Test("audio-only preset has no video codec")
    func audioOnlyPresetHasNoVideoCodec() {
        let config = CapturePreset.podcastAudio()
        #expect(config.videoCodec == nil)
    }

    @Test("video-only preset has no audio codec")
    func videoOnlyPresetHasNoAudioCodec() {
        let config = CapturePresetConfiguration(name: "test", category: .streaming, videoCodec: .h264)
        #expect(config.audioCodec == nil)
    }

    @Test("full AV preset has both codecs")
    func fullAVPresetHasBothCodecs() {
        let config = CapturePreset.twitch()
        #expect(config.audioCodec != nil)
        #expect(config.videoCodec != nil)
    }

    @Test("isAudioOnly returns true for no video")
    func isAudioOnlyReturnsTrueForNoVideo() {
        let config = CapturePreset.podcastAudio()
        #expect(config.isAudioOnly == true)
    }

    @Test("isVideoOnly returns true for no audio")
    func isVideoOnlyReturnsTrueForNoAudio() {
        let config = CapturePresetConfiguration(name: "test", category: .streaming, videoCodec: .h264)
        #expect(config.isVideoOnly == true)
    }

    @Test("name is descriptive")
    func nameIsDescriptive() {
        let config = CapturePreset.twitch()
        #expect(config.name.contains("Twitch"))
    }

    @Test("category matches preset type")
    func categoryMatchesPresetType() {
        let config = CapturePreset.twitch()
        #expect(config.category == .streaming)
    }

    @Test("Equatable conformance")
    func equatableConformance() {
        let config1 = CapturePreset.twitch()
        let config2 = CapturePreset.twitch()
        #expect(config1 == config2)
    }

    @Test("minimumHardware is nil for basic presets")
    func minimumHardwareIsNilForBasicPresets() {
        let config = CapturePreset.twitch()
        #expect(config.minimumHardware == nil)
    }

    @Test("minimumHardware set for ProRes")
    func minimumHardwareSetForProRes() {
        let config = CapturePreset.proResRecording()
        #expect(config.minimumHardware != nil)
    }

    @Test("isMacOSOnly true for MP3 presets")
    func isMacOSOnlyTrueForMP3Presets() {
        let config = CapturePreset.webRadioMP3()
        #expect(config.isMacOSOnly == true)
    }

    @Test("isMacOSOnly false for AAC presets")
    func isMacOSOnlyFalseForAACPresets() {
        let config = CapturePreset.twitch()
        #expect(config.isMacOSOnly == false)
    }
}
