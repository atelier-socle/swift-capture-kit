// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AudioEncoderPreset", .timeLimit(.minutes(1)))
struct AudioEncoderPresetTests {
    @Test("all cases exist in CaseIterable")
    func allCases() {
        #expect(AudioEncoderPreset.allCases.count == 16)
    }

    @Test("podcastStandard uses AAC codec")
    func podcastStandardCodec() {
        #expect(AudioEncoderPreset.podcastStandard.codec == .aac)
    }

    @Test("musicLossless uses ALAC codec")
    func musicLosslessCodec() {
        #expect(AudioEncoderPreset.musicLossless.codec == .alac)
    }

    @Test("voiceOpus uses Opus codec")
    func voiceOpusCodec() {
        #expect(AudioEncoderPreset.voiceOpus.codec == .opus)
    }

    @Test("broadcastPCM uses PCM codec")
    func broadcastPCMCodec() {
        #expect(AudioEncoderPreset.broadcastPCM.codec == .pcm)
    }

    @Test("broadcastFLAC uses FLAC codec")
    func broadcastFLACCodec() {
        #expect(AudioEncoderPreset.broadcastFLAC.codec == .flac)
    }

    @Test("webRadioMP3128 uses MP3 codec")
    func webRadioMP3Codec() {
        #expect(AudioEncoderPreset.webRadioMP3128.codec == .mp3)
    }

    @Test("webRadioMP3128 is macOS only")
    func webRadioMP3MacOSOnly() {
        #expect(AudioEncoderPreset.webRadioMP3128.isMacOSOnly == true)
    }

    @Test("podcastStandard is not macOS only")
    func podcastStandardNotMacOSOnly() {
        #expect(AudioEncoderPreset.podcastStandard.isMacOSOnly == false)
    }

    @Test("all preset codecs are valid AudioCodec values")
    func allPresetCodecsValid() {
        for preset in AudioEncoderPreset.allCases {
            #expect(AudioCodec.allCases.contains(preset.codec))
        }
    }
}
