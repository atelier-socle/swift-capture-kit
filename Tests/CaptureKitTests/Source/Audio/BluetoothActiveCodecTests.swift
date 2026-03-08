// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("BluetoothAudioSource Active Codec")
struct BluetoothActiveCodecTests {

    private func makeDevice() -> AudioDeviceInfo {
        AudioDeviceInfo(
            id: "bt-1", name: "Test BT",
            connectionType: .bluetooth, inputChannelCount: 1,
            supportedSampleRates: [.rate48000])
    }

    @Test("activeCodec is nil before capture")
    func activeCodecNilBeforeCapture() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(
            device: makeDevice(), captureEngine: MockAudioCaptureEngine())
        let codec = await source.activeCodec
        #expect(codec == nil)
    }

    @Test("activeCodec set from preferredCodec on start")
    func activeCodecSetFromPreferredCodec() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(
            device: makeDevice(), captureEngine: MockAudioCaptureEngine())
        await source.setPreferredCodecForTesting(BluetoothAudioCodec.aac)
        _ = try await source.startCapture()
        let codec = await source.activeCodec
        #expect(codec == BluetoothAudioCodec.aac)
    }

    @Test("activeCodec cleared on stop")
    func activeCodecClearedOnStop() async throws {
        guard #available(macOS 14.0, iOS 17.0, *) else { return }

        let source = BluetoothAudioSource(
            device: makeDevice(), captureEngine: MockAudioCaptureEngine())
        await source.setPreferredCodecForTesting(BluetoothAudioCodec.aac)
        _ = try await source.startCapture()
        await source.stopCapture()
        let codec = await source.activeCodec
        #expect(codec == nil)
    }
}

@available(macOS 14.0, iOS 17.0, *)
extension BluetoothAudioSource {
    func setPreferredCodecForTesting(_ codec: BluetoothAudioCodec?) {
        self.preferredCodec = codec
    }
}
