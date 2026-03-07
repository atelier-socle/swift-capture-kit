// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("BluetoothAudioCodec")
struct BluetoothAudioCodecTests {

    @Test("all eight cases exist")
    func allEightCasesExist() {
        #expect(BluetoothAudioCodec.allCases.count == 8)
    }

    @Test("rawValue correctness")
    func rawValueCorrectness() {
        #expect(BluetoothAudioCodec.sbc.rawValue == "sbc")
        #expect(BluetoothAudioCodec.aac.rawValue == "aac")
        #expect(BluetoothAudioCodec.aptx.rawValue == "aptx")
        #expect(BluetoothAudioCodec.aptxHD.rawValue == "aptxHD")
        #expect(BluetoothAudioCodec.aptxAdaptive.rawValue == "aptxAdaptive")
        #expect(BluetoothAudioCodec.ldac.rawValue == "ldac")
        #expect(BluetoothAudioCodec.lc3.rawValue == "lc3")
        #expect(BluetoothAudioCodec.opus.rawValue == "opus")
    }

    @Test("cases can be initialized from rawValue")
    func initFromRawValue() {
        #expect(BluetoothAudioCodec(rawValue: "sbc") == .sbc)
        #expect(BluetoothAudioCodec(rawValue: "aac") == .aac)
        #expect(BluetoothAudioCodec(rawValue: "aptx") == .aptx)
        #expect(BluetoothAudioCodec(rawValue: "aptxHD") == .aptxHD)
        #expect(BluetoothAudioCodec(rawValue: "aptxAdaptive") == .aptxAdaptive)
        #expect(BluetoothAudioCodec(rawValue: "ldac") == .ldac)
        #expect(BluetoothAudioCodec(rawValue: "lc3") == .lc3)
        #expect(BluetoothAudioCodec(rawValue: "opus") == .opus)
        #expect(BluetoothAudioCodec(rawValue: "invalid") == nil)
    }
}
