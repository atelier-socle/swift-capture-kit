// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

@testable import CaptureKit

/// Mock video capture engine for testing without hardware.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor MockVideoCaptureEngine: VideoCaptureProviding {
    private var _isCapturing = false
    var isCapturing: Bool { _isCapturing }

    /// Synthetic samples to emit when capture starts.
    var syntheticSamples: [CapturedVideoSample] = []

    /// Number of startCapture calls.
    var startCallCount = 0

    /// Number of stopCapture calls.
    var stopCallCount = 0

    /// Number of switchCamera calls.
    var switchCameraCallCount = 0

    /// The last position passed to startCapture.
    var lastPosition: CameraPosition?

    /// The last device type passed to startCapture.
    var lastDeviceType: CameraDeviceType?

    /// The last configuration passed to startCapture.
    var lastConfiguration: VideoSourceConfiguration?

    /// The last zoom factor passed to setZoom.
    var lastZoomFactor: Double?

    /// The last torch mode passed to setTorch.
    var lastTorchMode: TorchMode?

    /// Whether startCapture should throw.
    var shouldThrowOnStart = false

    func startCapture(
        configuration: VideoSourceConfiguration,
        position: CameraPosition,
        deviceType: CameraDeviceType
    ) async throws -> AsyncStream<CapturedVideoSample> {
        startCallCount += 1
        lastConfiguration = configuration
        lastPosition = position
        lastDeviceType = deviceType

        if shouldThrowOnStart {
            throw CaptureError.sourceNotAvailable(
                sourceType: "camera",
                reason: "Mock start error"
            )
        }

        _isCapturing = true
        let samples = syntheticSamples
        return AsyncStream { continuation in
            for sample in samples {
                continuation.yield(sample)
            }
            continuation.finish()
        }
    }

    func stopCapture() async {
        stopCallCount += 1
        _isCapturing = false
    }

    func switchCamera(to position: CameraPosition) async throws {
        switchCameraCallCount += 1
        lastPosition = position
    }

    func setZoom(_ factor: Double) async throws {
        lastZoomFactor = factor
    }

    func setTorch(_ mode: TorchMode) async throws {
        lastTorchMode = mode
    }

    /// The last photo settings passed to capturePhoto.
    var lastPhotoSettings: PhotoCaptureSettings?

    /// Whether depth data delivery was enabled.
    var depthDataDeliveryEnabled: Bool = false

    /// The last continuity features applied.
    var lastContinuityFeatures: ContinuityCameraFeatures?

    /// The last focus point set.
    var lastFocusPoint: (x: Double, y: Double)?

    /// The last focus mode set.
    var lastFocusMode: FocusMode?

    func capturePhoto(
        settings: PhotoCaptureSettings?
    ) async throws -> CapturedPhoto {
        lastPhotoSettings = settings
        return CapturedPhoto(
            data: Data([0xFF, 0xD8, 0xFF, 0xE0]),
            format: .jpeg,
            timestamp: 0.0,
            width: 1920,
            height: 1080
        )
    }

    func setDepthDataDelivery(_ enabled: Bool) async throws {
        depthDataDeliveryEnabled = enabled
    }

    func applyContinuityFeatures(
        _ features: ContinuityCameraFeatures
    ) async throws {
        lastContinuityFeatures = features
    }

    func setFocusPointOfInterest(x: Double, y: Double) async throws {
        lastFocusPoint = (x: x, y: y)
    }

    func setFocusMode(_ mode: FocusMode) async throws {
        lastFocusMode = mode
    }
}
