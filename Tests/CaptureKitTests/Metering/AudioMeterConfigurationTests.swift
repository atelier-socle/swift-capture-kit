// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("AudioMeterConfiguration", .timeLimit(.minutes(1)))
struct AudioMeterConfigurationTests {

    @Test("default values")
    func defaultValues() {
        let config = AudioMeterConfiguration()
        #expect(config.mode == .peakAndRMS)
        #expect(config.waveform == .disabled)
        #expect(config.updateRate == 60.0)
        #expect(config.peakHoldTime == 2.0)
        #expect(config.aWeighting == false)
    }

    @Test("broadcast preset")
    func broadcastPreset() {
        let config = AudioMeterConfiguration.broadcast
        #expect(config.mode == .full)
        #expect(config.waveform == .disabled)
        #expect(config.updateRate == 60.0)
        #expect(config.peakHoldTime == 3.0)
    }

    @Test("podcast preset has podcastEdit waveform")
    func podcastPreset() {
        let config = AudioMeterConfiguration.podcast
        #expect(config.mode == .peakAndRMS)
        #expect(config.waveform == .podcastEdit)
        #expect(config.updateRate == 30.0)
    }

    @Test("loudness compliance preset")
    func loudnessPreset() {
        let config = AudioMeterConfiguration.loudnessCompliance
        #expect(config.mode == .loudness)
        #expect(config.updateRate == 10.0)
    }

    @Test("voiceMessage preset has message waveform")
    func voiceMessagePreset() {
        let config = AudioMeterConfiguration.voiceMessage
        #expect(config.mode == .peakAndRMS)
        #expect(config.waveform == .message)
        #expect(config.updateRate == 30.0)
    }

    @Test("dawEditing preset has daw waveform")
    func dawEditingPreset() {
        let config = AudioMeterConfiguration.dawEditing
        #expect(config.mode == .full)
        #expect(config.waveform == .daw)
        #expect(config.updateRate == 60.0)
    }

    @Test("default waveform is disabled")
    func defaultWaveformDisabled() {
        let config = AudioMeterConfiguration()
        #expect(config.waveform == .disabled)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = AudioMeterConfiguration.broadcast
        let b = AudioMeterConfiguration.broadcast
        #expect(a == b)
    }

    @Test("different configs are not equal")
    func notEqual() {
        #expect(
            AudioMeterConfiguration.broadcast
                != AudioMeterConfiguration.podcast)
    }

    @Test("Sendable conformance compiles")
    func sendable() {
        let config: any Sendable = AudioMeterConfiguration.broadcast
        _ = config
    }
}
