// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if !os(visionOS)
    @preconcurrency import AVFoundation
    import Foundation

    /// Delegate to receive video sample buffers from AVCaptureVideoDataOutput.
    ///
    /// Bridges between the Objective-C delegate pattern and our async world.
    /// @unchecked Sendable justification: This class is only used as a delegate
    /// on a serial DispatchQueue. The handler closure is @Sendable. The class
    /// has no mutable state accessed from multiple threads.
    @available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
    private final class VideoCaptureDelegate: NSObject,
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

    /// Delegate to receive captured photos from AVCapturePhotoOutput.
    ///
    /// @unchecked Sendable justification: This class bridges the ObjC delegate
    /// callback to a Swift CheckedContinuation. The continuation is consumed
    /// exactly once. No mutable state is accessed from multiple threads.
    @available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
    private final class PhotoCaptureDelegate: NSObject,
        AVCapturePhotoCaptureDelegate, @unchecked Sendable
    {
        private var continuation: CheckedContinuation<CapturedPhoto, any Error>?

        init(continuation: CheckedContinuation<CapturedPhoto, any Error>) {
            self.continuation = continuation
        }

        func photoOutput(
            _ output: AVCapturePhotoOutput,
            didFinishProcessingPhoto photo: AVCapturePhoto,
            error: (any Error)?
        ) {
            guard let continuation = continuation else { return }
            self.continuation = nil

            if let error {
                continuation.resume(throwing: CaptureError.sourceNotAvailable(
                    sourceType: "camera",
                    reason: "Photo capture failed: \(error.localizedDescription)"
                ))
                return
            }

            guard let data = photo.fileDataRepresentation() else {
                continuation.resume(throwing: CaptureError.sourceNotAvailable(
                    sourceType: "camera",
                    reason: "No photo data available"
                ))
                return
            }

            let dimensions = photo.resolvedSettings.photoDimensions
            let capturedPhoto = CapturedPhoto(
                data: data,
                format: .heif,
                timestamp: ProcessInfo.processInfo.systemUptime,
                width: Int(dimensions.width),
                height: Int(dimensions.height)
            )
            continuation.resume(returning: capturedPhoto)
        }
    }

    /// Real video capture using AVCaptureSession + AVCaptureDevice.
    ///
    /// Actor isolation protects the non-Sendable AVCaptureSession.
    /// Used by CameraSource, ExternalCameraSource, CinematicCameraSource.
    @available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
    actor SystemVideoCaptureEngine: VideoCaptureProviding {
        private var captureSession: AVCaptureSession?
        private var videoOutput: AVCaptureVideoDataOutput?
        private var photoOutput: AVCapturePhotoOutput?
        private var currentDevice: AVCaptureDevice?
        private var photoCaptureDelegate: PhotoCaptureDelegate?
        private var _isCapturing = false

        var isCapturing: Bool { _isCapturing }

        func startCapture(
            configuration: VideoSourceConfiguration,
            position: CameraPosition,
            deviceType: CameraDeviceType
        ) async throws -> AsyncStream<CapturedVideoSample> {
            let session = AVCaptureSession()
            session.sessionPreset = sessionPreset(
                for: configuration.resolution)

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

            let photo = AVCapturePhotoOutput()
            if session.canAddOutput(photo) {
                session.addOutput(photo)
            }

            self.captureSession = session
            self.videoOutput = output
            self.photoOutput = photo
            self.currentDevice = device
            _isCapturing = true

            let config = configuration
            return AsyncStream { continuation in
                let delegate = VideoCaptureDelegate { sampleBuffer in
                    if let sample = Self.extractSample(
                        from: sampleBuffer, configuration: config)
                    {
                        continuation.yield(sample)
                    }
                }

                let queue = DispatchQueue(
                    label: "com.atelier-socle.capturekit.video")
                output.setSampleBufferDelegate(delegate, queue: queue)
                session.startRunning()

                continuation.onTermination = { [weak self] _ in
                    Task { await self?.stopCapture() }
                }
            }
        }

        func stopCapture() async {
            captureSession?.stopRunning()
            captureSession = nil
            videoOutput = nil
            photoOutput = nil
            photoCaptureDelegate = nil
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
            #if os(iOS)
                guard let device = currentDevice else { return }
                try device.lockForConfiguration()
                device.videoZoomFactor = CGFloat(
                    max(
                        device.minAvailableVideoZoomFactor,
                        min(
                            factor,
                            device.maxAvailableVideoZoomFactor)))
                device.unlockForConfiguration()
            #endif
        }

        func setTorch(_ mode: TorchMode) async throws {
            guard let device = currentDevice, device.hasTorch
            else { return }
            try device.lockForConfiguration()
            switch mode {
            case .off: device.torchMode = .off
            case .on: device.torchMode = .on
            case .auto: device.torchMode = .auto
            }
            device.unlockForConfiguration()
        }

        func capturePhoto(
            settings: PhotoCaptureSettings?
        ) async throws -> CapturedPhoto {
            guard let photoOutput else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "camera",
                    reason: "Photo output not available — call startCapture() first"
                )
            }

            let photoSettings = AVCapturePhotoSettings()
            if let settings {
                switch settings.flashMode {
                case .off: photoSettings.flashMode = .off
                case .on: photoSettings.flashMode = .on
                case .auto: photoSettings.flashMode = .auto
                }
            }

            return try await withCheckedThrowingContinuation { continuation in
                let delegate = PhotoCaptureDelegate(continuation: continuation)
                self.photoCaptureDelegate = delegate
                photoOutput.capturePhoto(
                    with: photoSettings, delegate: delegate)
            }
        }

        func setDepthDataDelivery(_ enabled: Bool) async throws {
            #if os(iOS)
                guard let session = captureSession else { return }
                session.beginConfiguration()
                if enabled {
                    let depthOutput = AVCaptureDepthDataOutput()
                    if session.canAddOutput(depthOutput) {
                        session.addOutput(depthOutput)
                        depthOutput.isFilteringEnabled = true
                    }
                } else {
                    for output in session.outputs
                    where output is AVCaptureDepthDataOutput {
                        session.removeOutput(output)
                    }
                }
                session.commitConfiguration()
            #endif
            // Depth data output is only available on iOS.
        }

        func applyContinuityFeatures(
            _ features: ContinuityCameraFeatures
        ) async throws {
            #if os(macOS)
                if features.centerStage {
                    AVCaptureDevice.centerStageControlMode = .cooperative
                    AVCaptureDevice.isCenterStageEnabled = true
                } else {
                    AVCaptureDevice.isCenterStageEnabled = false
                }
                // Portrait effect and Studio Light are user-controlled via
                // Control Center. Apple does not provide API to SET these —
                // only to query their current state via:
                // AVCaptureDevice.isPortraitEffectEnabled (class property)
                // AVCaptureDevice.isStudioLightEnabled (class property)
            #endif
        }

        func setFocusPointOfInterest(
            x: Double, y: Double
        ) async throws {
            guard let device = currentDevice else { return }
            guard device.isFocusPointOfInterestSupported else { return }
            try device.lockForConfiguration()
            device.focusPointOfInterest = CGPoint(x: x, y: y)
            device.focusMode = .autoFocus
            device.unlockForConfiguration()
        }

        func setFocusMode(_ mode: FocusMode) async throws {
            guard let device = currentDevice else { return }
            let avMode: AVCaptureDevice.FocusMode = switch mode {
            case .locked, .manualFocus: .locked
            case .autoFocus: .autoFocus
            case .continuousAutoFocus: .continuousAutoFocus
            }
            guard device.isFocusModeSupported(avMode) else { return }
            try device.lockForConfiguration()
            device.focusMode = avMode
            device.unlockForConfiguration()
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

    }
#endif
