// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CameraDeviceType", .timeLimit(.minutes(1)))
struct CameraDeviceTypeTests {

    @Test("CaseIterable count is 10")
    func caseIterableCount() {
        #expect(CameraDeviceType.allCases.count == 10)
    }

    @Test("rawValue matches expected strings")
    func rawValues() {
        #expect(CameraDeviceType.wideAngle.rawValue == "wideAngle")
        #expect(CameraDeviceType.ultraWideAngle.rawValue == "ultraWideAngle")
        #expect(CameraDeviceType.telephoto.rawValue == "telephoto")
        #expect(CameraDeviceType.dualCamera.rawValue == "dualCamera")
        #expect(CameraDeviceType.dualWideCamera.rawValue == "dualWideCamera")
        #expect(CameraDeviceType.tripleCamera.rawValue == "tripleCamera")
        #expect(CameraDeviceType.lidarScanner.rawValue == "lidarScanner")
        #expect(CameraDeviceType.trueDepth.rawValue == "trueDepth")
        #expect(CameraDeviceType.continuityCamera.rawValue == "continuityCamera")
        #expect(CameraDeviceType.externalUnknown.rawValue == "externalUnknown")
    }

    @Test("all cases exist")
    func allCasesExist() {
        let cases = CameraDeviceType.allCases
        #expect(cases.contains(.wideAngle))
        #expect(cases.contains(.ultraWideAngle))
        #expect(cases.contains(.telephoto))
        #expect(cases.contains(.dualCamera))
        #expect(cases.contains(.dualWideCamera))
        #expect(cases.contains(.tripleCamera))
        #expect(cases.contains(.lidarScanner))
        #expect(cases.contains(.trueDepth))
        #expect(cases.contains(.continuityCamera))
        #expect(cases.contains(.externalUnknown))
    }

    @Test("Sendable conformance allows use in Task")
    func sendableConformance() async {
        let deviceType = CameraDeviceType.telephoto
        let result = await Task { deviceType }.value
        #expect(result == .telephoto)
    }
}
