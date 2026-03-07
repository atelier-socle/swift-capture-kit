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

    /// Real video capture using AVCaptureSession + AVCaptureDevice.
    ///
    /// Actor isolation protects the non-Sendable AVCaptureSession.
    /// Used by CameraSource, ExternalCameraSource, CinematicCameraSource.
    @available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
    actor SystemVideoCaptureEngine: VideoCaptureProviding {
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

            self.captureSession = session
            self.videoOutput = output
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
            throw CaptureError.sourceNotAvailable(
                sourceType: "camera",
                reason: "Photo capture requires hardware camera"
            )
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
            let avPosition: AVCaptureDevice.Position =
                switch position {
                case .front: .front
                case .back: .back
                case .unspecified: .unspecified
                }

            let avDeviceType = avCaptureDeviceType(for: deviceType)

            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [avDeviceType],
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

        private func avCaptureDeviceType(
            for deviceType: CameraDeviceType
        ) -> AVCaptureDevice.DeviceType {
            switch deviceType {
            case .wideAngle:
                return .builtInWideAngleCamera
            #if os(iOS)
                case .ultraWideAngle:
                    return .builtInUltraWideCamera
                case .telephoto:
                    return .builtInTelephotoCamera
                case .dualCamera:
                    return .builtInDualCamera
                case .dualWideCamera:
                    return .builtInDualWideCamera
                case .tripleCamera:
                    return .builtInTripleCamera
                case .lidarScanner:
                    return .builtInLiDARDepthCamera
                case .trueDepth:
                    return .builtInTrueDepthCamera
            #endif
            case .continuityCamera:
                return .continuityCamera
            case .externalUnknown:
                return .external
            #if os(macOS)
                default:
                    return .builtInWideAngleCamera
            #endif
            }
        }

        private func sessionPreset(
            for resolution: VideoResolution
        ) -> AVCaptureSession.Preset {
            switch resolution {
            case .uhd4K, .dci4K: return .hd4K3840x2160
            case .p1080: return .hd1920x1080
            case .p720: return .hd1280x720
            case .vga: return .vga640x480
            case .qvga: return .cif352x288
            default: return .hd1920x1080
            }
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

            let desiredFPS = configuration.frameRate.value
            for format in device.formats {
                for range in format.videoSupportedFrameRateRanges
                where range.minFrameRate <= desiredFPS
                    && range.maxFrameRate >= desiredFPS
                {
                    device.activeFormat = format
                    device.activeVideoMinFrameDuration = CMTime(
                        value: 1,
                        timescale: CMTimeScale(desiredFPS))
                    device.activeVideoMaxFrameDuration = CMTime(
                        value: 1,
                        timescale: CMTimeScale(desiredFPS))
                    break
                }
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
