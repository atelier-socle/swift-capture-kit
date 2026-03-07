// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("BroadcastSample")
struct BroadcastSampleTests {

    @Test("BroadcastSample init stores properties")
    func broadcastSampleInit() {
        let data = Data([0x00, 0x01, 0x02])
        let sample = BroadcastSample(sampleType: .video, data: data, timestamp: 1234.0, sequenceNumber: 1)
        #expect(sample.sampleType == .video)
        #expect(sample.data == data)
        #expect(sample.timestamp == 1234.0)
        #expect(sample.sequenceNumber == 1)
    }

    @Test("BroadcastSampleType CaseIterable count is 3")
    func broadcastSampleTypeCaseIterableCount() {
        #expect(BroadcastSampleType.allCases.count == 3)
    }

    @Test("BroadcastSampleType rawValues")
    func broadcastSampleTypeRawValues() {
        #expect(BroadcastSampleType.video.rawValue == "video")
        #expect(BroadcastSampleType.audioApp.rawValue == "audioApp")
        #expect(BroadcastSampleType.audioMic.rawValue == "audioMic")
    }

    @Test("all BroadcastSampleType types exist")
    func allBroadcastSampleTypesExist() {
        let allCases = BroadcastSampleType.allCases
        #expect(allCases.contains(.video))
        #expect(allCases.contains(.audioApp))
        #expect(allCases.contains(.audioMic))
    }
}
