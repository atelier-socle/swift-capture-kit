// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// A raw video sample from the capture engine.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
struct CapturedVideoSample: Sendable {
    /// The raw pixel data.
    let data: Data
    /// The presentation timestamp in seconds.
    let timestamp: TimeInterval
    /// The video format of this sample.
    let format: VideoFormat
    /// Whether this frame is a key frame (raw capture frames are always independent).
    let isKeyFrame: Bool
    /// Optional metadata (e.g. bytesPerRow for IOSurface-backed frames).
    let metadata: [String: String]

    init(
        data: Data,
        timestamp: TimeInterval,
        format: VideoFormat,
        isKeyFrame: Bool,
        metadata: [String: String] = [:]
    ) {
        self.data = data
        self.timestamp = timestamp
        self.format = format
        self.isKeyFrame = isKeyFrame
        self.metadata = metadata
    }
}

/// Internal protocol abstracting video capture engine (AVCaptureSession).
///
/// Enables dependency injection for testing: real implementation uses
/// AVCaptureSession + AVCaptureDevice, tests inject a mock that
/// produces synthetic frames.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
protocol VideoCaptureProviding: Sendable {
    /// Start capturing video with the given configuration.
    ///
    /// - Parameters:
    ///   - configuration: The video source configuration.
    ///   - position: The camera position.
    ///   - deviceType: The camera device type preference.
    /// - Returns: An async stream of captured video samples.
    func startCapture(
        configuration: VideoSourceConfiguration,
        position: CameraPosition,
        deviceType: CameraDeviceType
    ) async throws -> AsyncStream<CapturedVideoSample>

    /// Stop capturing.
    func stopCapture() async

    /// Whether capture is currently active.
    var isCapturing: Bool { get async }

    /// Switch camera position without stopping capture.
    ///
    /// - Parameter position: The new camera position.
    func switchCamera(to position: CameraPosition) async throws

    /// Set zoom factor on the active device.
    ///
    /// - Parameter factor: The zoom factor (1.0 = no zoom).
    func setZoom(_ factor: Double) async throws

    /// Set torch mode on the active device.
    ///
    /// - Parameter mode: The torch mode.
    func setTorch(_ mode: TorchMode) async throws

    /// Capture a still photo during video recording.
    ///
    /// - Parameter settings: The photo capture settings.
    /// - Returns: The captured photo.
    func capturePhoto(
        settings: PhotoCaptureSettings?
    ) async throws -> CapturedPhoto

    /// Enable or disable depth data delivery alongside video.
    ///
    /// - Parameter enabled: Whether to enable depth data delivery.
    func setDepthDataDelivery(_ enabled: Bool) async throws

    /// Apply Continuity Camera features (Center Stage, etc.).
    ///
    /// - Parameter features: The Continuity Camera features to apply.
    func applyContinuityFeatures(
        _ features: ContinuityCameraFeatures
    ) async throws

    /// Set the focus point of interest on the active device.
    ///
    /// - Parameters:
    ///   - x: Normalized x coordinate (0.0–1.0).
    ///   - y: Normalized y coordinate (0.0–1.0).
    func setFocusPointOfInterest(x: Double, y: Double) async throws

    /// Set the focus mode on the active device.
    ///
    /// - Parameter mode: The focus mode to set.
    func setFocusMode(_ mode: FocusMode) async throws
}

/// Video capture engine for visionOS using AVCaptureSession with
/// enterprise main-camera entitlements.
///
/// On visionOS, sessionPreset is unavailable — resolution is configured
/// via AVCaptureDevice.activeFormat. Camera access requires the
/// com.apple.developer.arkit.main-camera-access.allow entitlement.
///
/// On the visionOS simulator, camera hardware is not available;
/// startCapture throws deviceNotFound so tests can use MockVideoCaptureEngine.
#if os(visionOS)
    @preconcurrency import AVFoundation

    /// Delegate to receive video sample buffers on visionOS.
    ///
    /// @unchecked Sendable justification: This class is only used as a delegate
    /// on a serial DispatchQueue. The handler closure is @Sendable. The class
    /// has no mutable state accessed from multiple threads.
    @available(visionOS 1.0, *)
    private final class VisionOSVideoCaptureDelegate: NSObject,
        AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable
    {
        private let handler: @Sendable (CMSampleBuffer) -> Void

        init(handler: @Sendable @escaping (CMSampleBuffer) -> Void) {
            self.handler = handler
        }

        func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            handler(sampleBuffer)
        }
    }

    @available(visionOS 1.0, *)
    actor VisionOSVideoCaptureEngine: VideoCaptureProviding {
        private var captureSession: AVCaptureSession?
        private var videoOutput: AVCaptureVideoDataOutput?
        private var currentDevice: AVCaptureDevice?
        private var _isCapturing = false

        var isCapturing: Bool { _isCapturing }

        func startCapture(
            configuration: VideoSourceConfiguration,
            position: CameraPosition,
            deviceType: CameraDeviceType
        ) async throws -> AsyncStream<CapturedVideoSample> {
            #if targetEnvironment(simulator)
                throw CaptureError.deviceNotFound(
                    deviceID: "visionOS-simulator-no-camera-hardware"
                )
            #else
                let session = AVCaptureSession()

                let device = try findDevice(
                    position: position, deviceType: deviceType)
                let input = try AVCaptureDeviceInput(device: device)
                guard session.canAddInput(input) else {
                    throw CaptureError.sourceNotAvailable(
                        sourceType: "camera",
                        reason: "Cannot add camera input to session"
                    )
                }
                session.addInput(input)

                try configureDevice(device, configuration: configuration)

                let output = AVCaptureVideoDataOutput()
                output.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String:
                        pixelFormatType(for: configuration.pixelFormat)
                ]
                output.alwaysDiscardsLateVideoFrames = true

                guard session.canAddOutput(output) else {
                    throw CaptureError.sourceNotAvailable(
                        sourceType: "camera",
                        reason: "Cannot add video output to session"
                    )
                }
                session.addOutput(output)

                self.captureSession = session
                self.videoOutput = output
                self.currentDevice = device
                _isCapturing = true

                let config = configuration
                return AsyncStream { continuation in
                    let delegate = VisionOSVideoCaptureDelegate { sampleBuffer in
                        if let sample = Self.extractSample(
                            from: sampleBuffer, configuration: config)
                        {
                            continuation.yield(sample)
                        }
                    }

                    let queue = DispatchQueue(
                        label: "com.atelier-socle.capturekit.visionos.video")
                    output.setSampleBufferDelegate(delegate, queue: queue)
                    session.startRunning()

                    continuation.onTermination = { [weak self] _ in
                        Task { await self?.stopCapture() }
                    }
                }
            #endif
        }

        func stopCapture() async {
            captureSession?.stopRunning()
            captureSession = nil
            videoOutput = nil
            currentDevice = nil
            _isCapturing = false
        }

        func switchCamera(to position: CameraPosition) async throws {
            guard let session = captureSession else { return }
            session.beginConfiguration()
            if let currentInput = session.inputs.first
                as? AVCaptureDeviceInput
            {
                session.removeInput(currentInput)
            }
            let device = try findDevice(
                position: position, deviceType: .wideAngle)
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
                self.currentDevice = device
            }
            session.commitConfiguration()
        }

        func setZoom(_ factor: Double) async throws {
            // Zoom is not supported on visionOS cameras.
        }

        func setTorch(_ mode: TorchMode) async throws {
            // Torch is not available on Apple Vision Pro.
        }

        func capturePhoto(
            settings: PhotoCaptureSettings?
        ) async throws -> CapturedPhoto {
            throw CaptureError.sourceNotAvailable(
                sourceType: "camera",
                reason: "Photo capture not supported on visionOS"
            )
        }

        func setDepthDataDelivery(_ enabled: Bool) async throws {
            // Depth data delivery is not available on visionOS standard capture.
        }

        func applyContinuityFeatures(
            _ features: ContinuityCameraFeatures
        ) async throws {
            // Continuity Camera is not available on visionOS.
        }

        func setFocusPointOfInterest(x: Double, y: Double) async throws {
            // Focus point of interest is not supported on visionOS cameras.
        }

        func setFocusMode(_ mode: FocusMode) async throws {
            // Focus mode changes are not supported on visionOS cameras.
        }

        // MARK: - Private Helpers

        private static func extractSample(
            from sampleBuffer: CMSampleBuffer,
            configuration: VideoSourceConfiguration
        ) -> CapturedVideoSample? {
            guard
                let pixelBuffer = CMSampleBufferGetImageBuffer(
                    sampleBuffer)
            else { return nil }

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            }

            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

            guard
                let baseAddress = CVPixelBufferGetBaseAddress(
                    pixelBuffer)
            else { return nil }

            let data = Data(
                bytes: baseAddress, count: bytesPerRow * height)
            let pts = CMSampleBufferGetPresentationTimeStamp(
                sampleBuffer)

            let format = VideoFormat(
                resolution: .custom(width: width, height: height),
                frameRate: configuration.frameRate,
                pixelFormat: configuration.pixelFormat,
                colorSpace: configuration.colorSpace,
                dynamicRange: configuration.dynamicRange
            )

            return CapturedVideoSample(
                data: data,
                timestamp: CMTimeGetSeconds(pts),
                format: format,
                isKeyFrame: true
            )
        }

        private func findDevice(
            position: CameraPosition,
            deviceType: CameraDeviceType
        ) throws -> AVCaptureDevice {
            guard #available(visionOS 2.1, *) else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "camera",
                    reason: "Camera capture requires visionOS 2.1 or newer"
                )
            }

            let avPosition: AVCaptureDevice.Position =
                switch position {
                case .front: .front
                case .back: .back
                case .unspecified: .unspecified
                }

            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: avPosition
            )

            guard let device = discoverySession.devices.first else {
                throw CaptureError.deviceNotFound(
                    deviceID:
                        "\(position.rawValue)-\(deviceType.rawValue)"
                )
            }
            return device
        }

        private func pixelFormatType(
            for pixelFormat: PixelFormat
        ) -> OSType {
            switch pixelFormat {
            case .nv12:
                return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            case .bgra:
                return kCVPixelFormatType_32BGRA
            case .p010:
                return kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
            case .p210:
                return kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange
            case .argb:
                return kCVPixelFormatType_32ARGB
            case .yuvs:
                return kCVPixelFormatType_422YpCbCr8_yuvs
            }
        }

        private func configureDevice(
            _ device: AVCaptureDevice,
            configuration: VideoSourceConfiguration
        ) throws {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            let desiredWidth = configuration.resolution.width
            let desiredHeight = configuration.resolution.height
            let desiredFPS = configuration.frameRate.value

            // On visionOS, sessionPreset is unavailable.
            // Select the best matching activeFormat by resolution and frame rate.
            var bestFormat: AVCaptureDevice.Format?
            var bestResolutionDiff = Int.max

            for format in device.formats {
                let desc = format.formatDescription
                let dimensions = CMVideoFormatDescriptionGetDimensions(desc)
                let formatWidth = Int(dimensions.width)
                let formatHeight = Int(dimensions.height)
                let diff =
                    abs(formatWidth - desiredWidth)
                    + abs(formatHeight - desiredHeight)

                for range in format.videoSupportedFrameRateRanges
                where range.minFrameRate <= desiredFPS
                    && range.maxFrameRate >= desiredFPS
                {
                    if diff < bestResolutionDiff {
                        bestResolutionDiff = diff
                        bestFormat = format
                    }
                }
            }

            if let format = bestFormat {
                device.activeFormat = format
                device.activeVideoMinFrameDuration = CMTime(
                    value: 1,
                    timescale: CMTimeScale(desiredFPS))
                device.activeVideoMaxFrameDuration = CMTime(
                    value: 1,
                    timescale: CMTimeScale(desiredFPS))
            }

            if device.isFocusModeSupported(.continuousAutoFocus),
                configuration.focusMode == .continuousAutoFocus
            {
                device.focusMode = .continuousAutoFocus
            }

            if device.isExposureModeSupported(.continuousAutoExposure),
                configuration.exposureMode == .continuousAutoExposure
            {
                device.exposureMode = .continuousAutoExposure
            }

            if device.isWhiteBalanceModeSupported(
                .continuousAutoWhiteBalance),
                configuration.whiteBalanceMode
                    == .continuousAutoWhiteBalance
            {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
        }
    }
#endif
