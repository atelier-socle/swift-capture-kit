// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("FileContainer", .timeLimit(.minutes(1)))
struct FileContainerTests {

    @Test("all 7 containers exist")
    func allContainersExist() {
        #expect(FileContainer.allCases.count == 7)
    }

    @Test("CaseIterable count is 7")
    func caseIterableCount() {
        let cases: [FileContainer] = [.mp4, .mov, .m4a, .caf, .wav, .aiff, .flac]
        #expect(cases.count == 7)
    }

    @Test("mp4 supports video")
    func mp4SupportsVideo() {
        #expect(FileContainer.mp4.supportsVideo)
    }

    @Test("mov supports video")
    func movSupportsVideo() {
        #expect(FileContainer.mov.supportsVideo)
    }

    @Test("m4a does not support video")
    func m4aDoesNotSupportVideo() {
        #expect(!FileContainer.m4a.supportsVideo)
    }

    @Test("wav does not support video")
    func wavDoesNotSupportVideo() {
        #expect(!FileContainer.wav.supportsVideo)
    }

    @Test("caf does not support video")
    func cafDoesNotSupportVideo() {
        #expect(!FileContainer.caf.supportsVideo)
    }

    @Test("aiff does not support video")
    func aiffDoesNotSupportVideo() {
        #expect(!FileContainer.aiff.supportsVideo)
    }

    @Test("flac does not support video")
    func flacDoesNotSupportVideo() {
        #expect(!FileContainer.flac.supportsVideo)
    }

    @Test("fileExtension matches case name")
    func fileExtensionMatchesCaseName() {
        for container in FileContainer.allCases {
            #expect(container.fileExtension == container.rawValue)
        }
    }

    @Test("all containers support audio")
    func allContainersSupportAudio() {
        for container in FileContainer.allCases {
            #expect(container.supportsAudio)
        }
    }

    @Test("mp4 supports H264 and HEVC codecs")
    func mp4SupportsH264AndHEVC() {
        let codecs = FileContainer.mp4.supportedVideoCodecs
        #expect(codecs.contains(.h264))
        #expect(codecs.contains(.hevc))
    }

    @Test("mov supports ProRes")
    func movSupportsProRes() {
        let codecs = FileContainer.mov.supportedVideoCodecs
        #expect(codecs.contains(.prores))
    }

    @Test("audio-only containers have empty video codecs")
    func audioOnlyContainersHaveEmptyVideoCodecs() {
        for container: FileContainer in [.m4a, .caf, .wav, .aiff, .flac] {
            #expect(container.supportedVideoCodecs.isEmpty)
        }
    }

    @Test("wav supports only PCM audio")
    func wavSupportsOnlyPCM() {
        #expect(FileContainer.wav.supportedAudioCodecs == [.pcm])
    }

    @Test("caf supports many audio codecs")
    func cafSupportsMultipleCodecs() {
        let codecs = FileContainer.caf.supportedAudioCodecs
        #expect(codecs.contains(.aac))
        #expect(codecs.contains(.pcm))
        #expect(codecs.contains(.opus))
    }
}
