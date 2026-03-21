// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CaptureError", .timeLimit(.minutes(1)))
struct CaptureErrorTests {

    @Test("Session errors have correct description text")
    func sessionErrorDescriptions() {
        #expect(
            CaptureError.sessionNotConfigured.description
                == "The capture session has not been configured.")
        #expect(
            CaptureError.sessionAlreadyRunning.description
                == "The capture session is already running.")
        #expect(
            CaptureError.sessionNotRunning.description
                == "The capture session is not running.")
        #expect(
            CaptureError.invalidConfiguration("bad value").description
                == "Invalid session configuration: bad value.")
    }

    @Test("Source errors include context info in description")
    func sourceErrorDescriptions() {
        #expect(
            CaptureError.sourceNotAvailable(sourceType: "mic", reason: "offline").description
                == "Source 'mic' is not available: offline.")
        #expect(
            CaptureError.sourceAlreadyCapturing(sourceID: "src-1").description
                == "Source 'src-1' is already capturing.")
        #expect(
            CaptureError.deviceNotFound(deviceID: "dev-1").description
                == "Device 'dev-1' was not found.")
    }

    @Test("Encoder errors include context info in description")
    func encoderErrorDescriptions() {
        #expect(
            CaptureError.encoderNotAvailable(codec: "aac", reason: "missing").description
                == "Encoder for codec 'aac' is not available: missing.")
        #expect(
            CaptureError.encodingFailed(codec: "h264", reason: "timeout").description
                == "Encoding with codec 'h264' failed: timeout.")
        #expect(
            CaptureError.hardwareEncoderBusy.description
                == "The hardware encoder is busy and cannot accept new work.")
    }

    @Test("Permission errors include type info in description")
    func permissionErrorDescriptions() {
        #expect(
            CaptureError.permissionDenied(.microphone).description
                == "Permission denied for microphone.")
        #expect(
            CaptureError.permissionNotDetermined(.camera).description
                == "Permission not yet determined for camera.")
    }

    @Test("Device errors have descriptions")
    func deviceErrorDescriptions() {
        #expect(
            CaptureError.noAudioDeviceAvailable.description
                == "No audio device is available.")
        #expect(
            CaptureError.noVideoDeviceAvailable.description
                == "No video device is available.")
        #expect(
            CaptureError.deviceInUseByAnotherProcess(deviceID: "dev-2").description
                == "Device 'dev-2' is in use by another process.")
    }

    @Test("Every error case has a non-empty description")
    func allDescriptionsNonEmpty() {
        let errors: [CaptureError] = [
            .sessionNotConfigured,
            .sessionAlreadyRunning,
            .sessionNotRunning,
            .invalidConfiguration("test"),
            .sourceNotAvailable(sourceType: "mic", reason: "test"),
            .sourceAlreadyCapturing(sourceID: "s1"),
            .sourceConfigurationFailed(sourceID: "s1", reason: "test"),
            .deviceNotFound(deviceID: "d1"),
            .deviceDisconnected(deviceID: "d1"),
            .formatNotSupported(format: "f1"),
            .encoderNotAvailable(codec: "c1", reason: "test"),
            .encoderConfigurationFailed(codec: "c1", reason: "test"),
            .encodingFailed(codec: "c1", reason: "test"),
            .hardwareEncoderBusy,
            .codecNotSupportedOnPlatform(codec: "c1", platform: "macOS"),
            .outputPrepareFailed(outputID: "o1", reason: "test"),
            .outputWriteFailed(outputID: "o1", reason: "test"),
            .fileOutputDirectoryNotWritable(path: "/tmp"),
            .fileOutputRotationFailed(reason: "test"),
            .permissionDenied(.microphone),
            .permissionNotDetermined(.camera),
            .noAudioDeviceAvailable,
            .noVideoDeviceAvailable,
            .aggregateDeviceCreationFailed(reason: "test"),
            .deviceInUseByAnotherProcess(deviceID: "d1"),
            .sampleRateConversionFailed,
            .channelLayoutConversionFailed,
            .pixelFormatConversionFailed,
            .colorSpaceConversionFailed
        ]
        for error in errors {
            #expect(!error.description.isEmpty)
        }
    }

    @Test("Error conforms to Error protocol and can be thrown and caught")
    func errorConformance() {
        do {
            throw CaptureError.sessionNotConfigured
        } catch let error as CaptureError {
            #expect(!error.description.isEmpty)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Sendable conformance")
    func sendableConformance() {
        let error: any Sendable = CaptureError.sessionNotConfigured
        #expect(error is CaptureError)
    }
}
