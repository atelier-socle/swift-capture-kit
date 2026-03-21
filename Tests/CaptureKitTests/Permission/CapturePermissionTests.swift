// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CapturePermission", .timeLimit(.minutes(1)))
struct CapturePermissionTests {

    @Test("all 3 cases exist")
    func allCases() {
        #expect(CapturePermission.allCases.count == 3)
    }

    @Test("microphone maps to PermissionType.microphone")
    func microphoneMapping() {
        #expect(
            CapturePermission.microphone.permissionType == .microphone)
    }

    @Test("camera maps to PermissionType.camera")
    func cameraMapping() {
        #expect(CapturePermission.camera.permissionType == .camera)
    }

    @Test("screenCapture maps to PermissionType.screenRecording")
    func screenCaptureMapping() {
        #expect(
            CapturePermission.screenCapture.permissionType
                == .screenRecording)
    }

    @Test("raw values are correct")
    func rawValues() {
        #expect(CapturePermission.microphone.rawValue == "microphone")
        #expect(CapturePermission.camera.rawValue == "camera")
        #expect(
            CapturePermission.screenCapture.rawValue == "screenCapture")
    }
}
