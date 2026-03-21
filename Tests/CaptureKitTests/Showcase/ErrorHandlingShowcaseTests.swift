// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("Error Handling Showcase", .tags(.showcase))
struct ErrorHandlingShowcaseTests {

    // MARK: - Session Errors

    @Test("sessionNotConfigured has description")
    func sessionNotConfigured() {
        let error = CaptureError.sessionNotConfigured
        #expect(error.description.isEmpty == false)
    }

    @Test("sessionAlreadyRunning has description")
    func sessionAlreadyRunning() {
        let error = CaptureError.sessionAlreadyRunning
        #expect(error.description.isEmpty == false)
    }

    @Test("sessionNotRunning has description")
    func sessionNotRunning() {
        let error = CaptureError.sessionNotRunning
        #expect(error.description.isEmpty == false)
    }

    @Test("invalidConfiguration includes reason")
    func invalidConfiguration() {
        let error = CaptureError.invalidConfiguration(
            "bitrate must be positive"
        )
        #expect(error.description.contains("bitrate"))
    }

    // MARK: - Source Errors

    @Test("sourceNotAvailable includes source type and reason")
    func sourceNotAvailable() {
        let error = CaptureError.sourceNotAvailable(
            sourceType: "microphone",
            reason: "no device found"
        )
        #expect(error.description.contains("microphone"))
    }

    @Test("sourceAlreadyCapturing includes source ID")
    func sourceAlreadyCapturing() {
        let error = CaptureError.sourceAlreadyCapturing(
            sourceID: "mic-01"
        )
        #expect(error.description.contains("mic-01"))
    }

    @Test("sourceConfigurationFailed includes details")
    func sourceConfigurationFailed() {
        let error = CaptureError.sourceConfigurationFailed(
            sourceID: "cam-01",
            reason: "unsupported resolution"
        )
        #expect(error.description.contains("cam-01"))
    }

    @Test("deviceNotFound includes device ID")
    func deviceNotFound() {
        let error = CaptureError.deviceNotFound(
            deviceID: "0x1234"
        )
        #expect(error.description.contains("0x1234"))
    }

    @Test("deviceDisconnected includes device ID")
    func deviceDisconnected() {
        let error = CaptureError.deviceDisconnected(
            deviceID: "usb-mic"
        )
        #expect(error.description.contains("usb-mic"))
    }

    @Test("formatNotSupported includes format description")
    func formatNotSupported() {
        let error = CaptureError.formatNotSupported(
            format: "96kHz 32-bit"
        )
        #expect(error.description.contains("96kHz"))
    }

    // MARK: - Encoder Errors

    @Test("encoderNotAvailable includes codec and reason")
    func encoderNotAvailable() {
        let error = CaptureError.encoderNotAvailable(
            codec: "AV1",
            reason: "hardware not supported"
        )
        #expect(error.description.contains("AV1"))
    }

    @Test("encoderConfigurationFailed includes details")
    func encoderConfigurationFailed() {
        let error = CaptureError.encoderConfigurationFailed(
            codec: "HEVC",
            reason: "invalid bitrate"
        )
        #expect(error.description.contains("HEVC"))
    }

    @Test("encodingFailed includes codec and reason")
    func encodingFailed() {
        let error = CaptureError.encodingFailed(
            codec: "AAC",
            reason: "buffer underrun"
        )
        #expect(error.description.contains("AAC"))
    }

    @Test("hardwareEncoderBusy has description")
    func hardwareEncoderBusy() {
        let error = CaptureError.hardwareEncoderBusy
        #expect(error.description.isEmpty == false)
    }

    @Test("codecNotSupportedOnPlatform includes details")
    func codecNotSupportedOnPlatform() {
        let error = CaptureError.codecNotSupportedOnPlatform(
            codec: "MP3",
            platform: "iOS"
        )
        #expect(error.description.contains("MP3"))
        #expect(error.description.contains("iOS"))
    }

    // MARK: - Output Errors

    @Test("outputPrepareFailed includes output ID")
    func outputPrepareFailed() {
        let error = CaptureError.outputPrepareFailed(
            outputID: "file-writer",
            reason: "disk full"
        )
        #expect(error.description.contains("file-writer"))
    }

    @Test("outputWriteFailed includes details")
    func outputWriteFailed() {
        let error = CaptureError.outputWriteFailed(
            outputID: "stream-01",
            reason: "connection lost"
        )
        #expect(error.description.contains("stream-01"))
    }

    @Test("fileOutputDirectoryNotWritable includes path")
    func fileOutputDirectoryNotWritable() {
        let error = CaptureError.fileOutputDirectoryNotWritable(
            path: "/readonly/dir"
        )
        #expect(error.description.contains("/readonly/dir"))
    }

    @Test("fileOutputRotationFailed includes reason")
    func fileOutputRotationFailed() {
        let error = CaptureError.fileOutputRotationFailed(
            reason: "max files reached"
        )
        #expect(error.description.contains("max files"))
    }

    // MARK: - Permission Errors

    @Test("permissionDenied includes permission type")
    func permissionDenied() {
        let error = CaptureError.permissionDenied(.microphone)
        #expect(error.description.isEmpty == false)
    }

    @Test("permissionNotDetermined includes permission type")
    func permissionNotDetermined() {
        let error = CaptureError.permissionNotDetermined(.camera)
        #expect(error.description.isEmpty == false)
    }

    @Test("PermissionType enumerates all types")
    func permissionTypes() {
        let types = PermissionType.allCases
        #expect(types.contains(.microphone))
        #expect(types.contains(.camera))
        #expect(types.contains(.screenRecording))
    }

    // MARK: - Device Errors

    @Test("noAudioDeviceAvailable has description")
    func noAudioDevice() {
        let error = CaptureError.noAudioDeviceAvailable
        #expect(error.description.isEmpty == false)
    }

    @Test("noVideoDeviceAvailable has description")
    func noVideoDevice() {
        let error = CaptureError.noVideoDeviceAvailable
        #expect(error.description.isEmpty == false)
    }

    @Test("aggregateDeviceCreationFailed includes reason")
    func aggregateDeviceFailed() {
        let error = CaptureError.aggregateDeviceCreationFailed(
            reason: "incompatible sample rates"
        )
        #expect(error.description.contains("incompatible"))
    }

    @Test("deviceInUseByAnotherProcess includes device ID")
    func deviceInUse() {
        let error = CaptureError.deviceInUseByAnotherProcess(
            deviceID: "built-in-mic"
        )
        #expect(error.description.contains("built-in-mic"))
    }

    // MARK: - Format Conversion Errors

    @Test("sampleRateConversionFailed has description")
    func sampleRateConversion() {
        let error = CaptureError.sampleRateConversionFailed
        #expect(error.description.isEmpty == false)
    }

    @Test("channelLayoutConversionFailed has description")
    func channelLayoutConversion() {
        let error = CaptureError.channelLayoutConversionFailed
        #expect(error.description.isEmpty == false)
    }

    @Test("pixelFormatConversionFailed has description")
    func pixelFormatConversion() {
        let error = CaptureError.pixelFormatConversionFailed
        #expect(error.description.isEmpty == false)
    }

    @Test("colorSpaceConversionFailed has description")
    func colorSpaceConversion() {
        let error = CaptureError.colorSpaceConversionFailed
        #expect(error.description.isEmpty == false)
    }

    // MARK: - CaptureError is Sendable

    @Test("CaptureError conforms to Sendable")
    func captureErrorIsSendable() {
        let error: any Sendable = CaptureError.sessionNotConfigured
        #expect(error is CaptureError)
    }
}
