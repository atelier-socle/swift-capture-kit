// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("LineInSource Input Gain")
struct LineInSourceInputGainTests {

    private func makeDevice() -> AudioDeviceInfo {
        AudioDeviceInfo(
            id: "line-1", name: "Test Line In",
            connectionType: .usb, inputChannelCount: 2,
            supportedSampleRates: [.rate48000])
    }

    @Test("startCapture applies input gain to engine")
    func startCaptureAppliesInputGain() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let engine = MockAudioCaptureEngine()
        let source = LineInSource(
            device: makeDevice(), inputGain: 0.5, captureEngine: engine)
        _ = try await source.startCapture()
        let gain = await engine.lastInputGain
        #expect(gain == 0.5)
    }

    @Test("input gain clamped in init")
    func inputGainClampedToMax() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(
            device: makeDevice(), inputGain: 2.0, captureEngine: MockAudioCaptureEngine())
        let gain = await source.inputGain
        #expect(gain == 1.0)
    }

    @Test("input gain clamped to zero")
    func inputGainClampedToZero() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = LineInSource(
            device: makeDevice(), inputGain: -1.0, captureEngine: MockAudioCaptureEngine())
        let gain = await source.inputGain
        #expect(gain == 0.0)
    }
}
