// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing
@testable import CaptureKit

@Suite("CapturePreset Utility Factory Methods")
struct CapturePresetUtilityTests {

    // MARK: - Screen Recording

    @Test("screenRecording returns H264 1080p configuration with default frame rate")
    func screenRecordingDefaultFrameRate() {
        let config = CapturePreset.screenRecording()
        #expect(config.name == "Screen Recording")
        #expect(config.category == .screenRecording)
        #expect(config.audioCodec == .aac)
        #expect(config.audioBitrate == 128_000)
        #expect(config.videoCodec == .h264)
        #expect(config.videoBitrate == 5_000_000)
        #expect(config.videoResolution == .p1080)
        #expect(config.videoFrameRate == .fps30)
        #expect(!config.isAudioOnly)
    }

    @Test("screenRecording accepts custom frame rate")
    func screenRecordingCustomFrameRate() {
        let config = CapturePreset.screenRecording(frameRate: .fps60)
        #expect(config.videoFrameRate == .fps60)
    }

    @Test("screenRecording4K returns HEVC 4K configuration")
    func screenRecording4KConfiguration() {
        let config = CapturePreset.screenRecording4K()
        #expect(config.name == "Screen Recording 4K")
        #expect(config.category == .screenRecording)
        #expect(config.audioCodec == .aac)
        #expect(config.videoCodec == .hevc)
        #expect(config.videoBitrate == 15_000_000)
        #expect(config.videoResolution == .uhd4K)
        #expect(config.videoFrameRate == .fps30)
    }

    @Test("screenRecordingRetina returns H264 4K 60fps configuration")
    func screenRecordingRetinaConfiguration() {
        let config = CapturePreset.screenRecordingRetina()
        #expect(config.name == "Screen Recording Retina")
        #expect(config.category == .screenRecording)
        #expect(config.videoCodec == .h264)
        #expect(config.videoBitrate == 20_000_000)
        #expect(config.videoResolution == .uhd4K)
        #expect(config.videoFrameRate == .fps60)
    }

    // MARK: - Low Bandwidth

    @Test("lowBandwidth returns VGA H264 low bitrate configuration")
    func lowBandwidthConfiguration() {
        let config = CapturePreset.lowBandwidth()
        #expect(config.name == "Low Bandwidth")
        #expect(config.category == .lowBandwidth)
        #expect(config.audioCodec == .aac)
        #expect(config.audioBitrate == 64_000)
        #expect(config.audioSampleRate == .rate44100)
        #expect(config.videoCodec == .h264)
        #expect(config.videoBitrate == 400_000)
        #expect(config.videoResolution == .vga)
        #expect(config.videoFrameRate == .fps15)
    }

    @Test("voiceOnly returns audio-only AAC mono configuration")
    func voiceOnlyConfiguration() {
        let config = CapturePreset.voiceOnly()
        #expect(config.name == "Voice Only")
        #expect(config.category == .lowBandwidth)
        #expect(config.audioCodec == .aac)
        #expect(config.audioBitrate == 32_000)
        #expect(config.audioSampleRate == .rate16000)
        #expect(config.audioChannelCount == 1)
        #expect(config.isAudioOnly)
    }

    // MARK: - Archive

    @Test("archiveLossless returns ALAC and HEVC maximum quality configuration")
    func archiveLosslessConfiguration() {
        let config = CapturePreset.archiveLossless()
        #expect(config.name == "Archive Lossless")
        #expect(config.category == .archive)
        #expect(config.audioCodec == .alac)
        #expect(config.audioSampleRate == .rate96000)
        #expect(config.audioChannelCount == 2)
        #expect(config.videoCodec == .hevc)
        #expect(config.videoBitrate == 100_000_000)
        #expect(config.videoResolution == .uhd4K)
    }

    @Test("archive4K returns FLAC and HEVC 4K configuration")
    func archive4KConfiguration() {
        let config = CapturePreset.archive4K()
        #expect(config.name == "Archive 4K")
        #expect(config.category == .archive)
        #expect(config.audioCodec == .flac)
        #expect(config.audioSampleRate == .rate96000)
        #expect(config.videoCodec == .hevc)
        #expect(config.videoBitrate == 50_000_000)
        #expect(config.videoResolution == .uhd4K)
        #expect(config.videoFrameRate == .fps30)
    }

    // MARK: - Cross-cutting

    @Test("screen recording presets are not macOS only")
    func screenRecordingPresetsNotMacOSOnly() {
        #expect(!CapturePreset.screenRecording().isMacOSOnly)
        #expect(!CapturePreset.screenRecording4K().isMacOSOnly)
        #expect(!CapturePreset.screenRecordingRetina().isMacOSOnly)
    }

    @Test("utility presets have no minimum hardware requirement")
    func utilityPresetsNoMinimumHardware() {
        #expect(CapturePreset.screenRecording().minimumHardware == nil)
        #expect(CapturePreset.lowBandwidth().minimumHardware == nil)
        #expect(CapturePreset.voiceOnly().minimumHardware == nil)
    }
}
