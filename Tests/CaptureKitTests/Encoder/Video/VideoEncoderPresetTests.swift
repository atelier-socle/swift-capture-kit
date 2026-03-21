// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("VideoEncoderPreset", .timeLimit(.minutes(1)))
struct VideoEncoderPresetTests {
    @Test("all cases exist in CaseIterable")
    func allCases() {
        #expect(VideoEncoderPreset.allCases.count == 18)
    }

    @Test("streaming presets use H264 or HEVC or AV1")
    func streamingCodecs() {
        let streamingCodecs: Set<VideoCodec> = [.h264, .hevc, .av1]
        #expect(
            streamingCodecs.contains(
                VideoEncoderPreset.streaming720pH264.codec
            ))
        #expect(
            streamingCodecs.contains(
                VideoEncoderPreset.streaming1080pHEVC.codec
            ))
        #expect(
            streamingCodecs.contains(
                VideoEncoderPreset.streaming1080pAV1.codec
            ))
    }

    @Test("proresProxy uses ProRes codec")
    func proresCodec() {
        #expect(VideoEncoderPreset.proresProxy.codec == .prores)
    }

    @Test("spatialVideo uses mvHevc codec")
    func spatialVideoCodec() {
        #expect(VideoEncoderPreset.spatialVideo.codec == .mvHevc)
    }

    @Test("lowLatencyJPEG uses JPEG codec")
    func lowLatencyJPEGCodec() {
        #expect(VideoEncoderPreset.lowLatencyJPEG.codec == .jpeg)
    }

    @Test("streaming1080pAV1 requires M3+ hardware")
    func av1RequiresM3() {
        #expect(
            VideoEncoderPreset.streaming1080pAV1.minimumHardware
                == "Apple M3"
        )
    }

    @Test("proresHQ requires M1+ hardware")
    func proresRequiresM1() {
        #expect(
            VideoEncoderPreset.proresHQ.minimumHardware == "Apple M1"
        )
    }

    @Test("streaming1080pH264 has no minimum hardware")
    func h264NoMinHardware() {
        #expect(
            VideoEncoderPreset.streaming1080pH264.minimumHardware == nil
        )
    }

    @Test("all preset codecs are valid VideoCodec values")
    func allCodecsValid() {
        for preset in VideoEncoderPreset.allCases {
            #expect(VideoCodec.allCases.contains(preset.codec))
        }
    }

    @Test("screenRecording presets exist")
    func screenRecordingPresets() {
        #expect(
            VideoEncoderPreset.screenRecordingH264.codec == .h264
        )
        #expect(
            VideoEncoderPreset.screenRecordingHEVC.codec == .hevc
        )
    }
}
