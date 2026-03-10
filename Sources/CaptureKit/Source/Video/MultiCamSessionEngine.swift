// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if os(iOS)
    @preconcurrency import AVFoundation
    import Foundation

    /// Manages an `AVCaptureMultiCamSession` on iOS for true simultaneous
    /// multi-camera capture.
    ///
    /// iOS only allows one active `AVCaptureSession` at a time. When multiple
    /// cameras are needed, `AVCaptureMultiCamSession` (iPhone 11+) must be used
    /// instead of separate sessions. This engine sets up all camera inputs and
    /// outputs in a single session and exposes per-camera `AsyncStream`s.
    @available(iOS 17.0, *)
    actor MultiCamSessionEngine {

        // MARK: - Properties

        private var multiCamSession: AVCaptureMultiCamSession?
        private var delegates: [String: MultiCamOutputDelegate] = [:]
        private var _isCapturing = false

        var isCapturing: Bool { _isCapturing }

        /// Whether the device supports `AVCaptureMultiCamSession`.
        nonisolated static var isSupported: Bool {
            AVCaptureMultiCamSession.isMultiCamSupported
        }

        // MARK: - Capture

        /// Starts multi-camera capture with all configured cameras.
        ///
        /// - Parameters:
        ///   - cameras: The camera inputs to capture from (minimum 2).
        ///   - configuration: The video source configuration applied to all cameras.
        /// - Returns: A dictionary mapping camera labels to their frame streams.
        func startCapture(
            cameras: [MultiCameraInput],
            configuration: VideoSourceConfiguration
        ) throws -> [String: AsyncStream<CapturedVideoSample>] {
            let session = AVCaptureMultiCamSession()
            var streams: [String: AsyncStream<CapturedVideoSample>] = [:]

            session.beginConfiguration()
            for camera in cameras {
                let stream = try addCamera(
                    camera, to: session, configuration: configuration)
                streams[camera.label] = stream
            }
            session.commitConfiguration()
            session.startRunning()

            self.multiCamSession = session
            self._isCapturing = true
            print(
                "📷 [MultiCam] AVCaptureMultiCamSession started with \(cameras.count) cameras"
            )
            return streams
        }

        /// Adds a single camera input+output+connection to the session.
        private func addCamera(
            _ camera: MultiCameraInput,
            to session: AVCaptureMultiCamSession,
            configuration: VideoSourceConfiguration
        ) throws -> AsyncStream<CapturedVideoSample> {
            let device = try findDevice(
                position: camera.device.position,
                deviceType: camera.device.deviceType
            )

            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "multi-camera",
                    reason: "Cannot add input for \(camera.label)")
            }
            session.addInputWithNoConnections(input)
            try configureDeviceForMultiCam(device, configuration: configuration)

            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String:
                    pixelFormatType(for: configuration.pixelFormat)
            ]
            output.alwaysDiscardsLateVideoFrames = true

            guard session.canAddOutput(output) else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "multi-camera",
                    reason: "Cannot add output for \(camera.label)")
            }
            session.addOutputWithNoConnections(output)

            guard
                let port = input.ports(
                    for: .video,
                    sourceDeviceType: device.deviceType,
                    sourceDevicePosition: device.position
                ).first
            else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "multi-camera",
                    reason: "No video port for \(camera.label)")
            }

            let connection = AVCaptureConnection(
                inputPorts: [port], output: output)
            guard session.canAddConnection(connection) else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "multi-camera",
                    reason: "Cannot connect input→output for \(camera.label)")
            }
            session.addConnection(connection)

            let config = configuration
            let (stream, continuation) = AsyncStream.makeStream(of: CapturedVideoSample.self)
            let delegate = MultiCamOutputDelegate { sampleBuffer in
                if let sample = Self.extractSample(
                    from: sampleBuffer, configuration: config)
                {
                    continuation.yield(sample)
                }
            }
            let queue = DispatchQueue(
                label: "com.atelier-socle.capturekit.multicam.\(camera.label)")
            output.setSampleBufferDelegate(delegate, queue: queue)

            delegates[camera.label] = delegate
            print(
                "📷 [MultiCam] Configured \(camera.label): \(device.localizedName) (\(device.position.rawValue))"
            )
            return stream
        }

        /// Stops the multi-camera session.
        func stopCapture() {
            multiCamSession?.stopRunning()
            multiCamSession = nil
            delegates.removeAll()
            _isCapturing = false
            print("📷 [MultiCam] AVCaptureMultiCamSession stopped")
        }

        // MARK: - Private Helpers

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
            case .wideAngle: .builtInWideAngleCamera
            case .ultraWideAngle: .builtInUltraWideCamera
            case .telephoto: .builtInTelephotoCamera
            case .dualCamera: .builtInDualCamera
            case .dualWideCamera: .builtInDualWideCamera
            case .tripleCamera: .builtInTripleCamera
            case .lidarScanner: .builtInLiDARDepthCamera
            case .trueDepth: .builtInTrueDepthCamera
            case .continuityCamera: .continuityCamera
            case .externalUnknown: .external
            }
        }

        private func pixelFormatType(
            for pixelFormat: PixelFormat
        ) -> OSType {
            switch pixelFormat {
            case .nv12: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            case .bgra: kCVPixelFormatType_32BGRA
            case .p010: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange
            case .p210: kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange
            case .argb: kCVPixelFormatType_32ARGB
            case .yuvs: kCVPixelFormatType_422YpCbCr8_yuvs
            }
        }

        /// Configures a device for multi-cam bandwidth constraints.
        ///
        /// Multi-cam sessions have limited bandwidth — each camera should use
        /// a moderate resolution (720p or 1080p max), not the native sensor
        /// resolution (e.g. 4032×3024).
        private func configureDeviceForMultiCam(
            _ device: AVCaptureDevice,
            configuration: VideoSourceConfiguration
        ) throws {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }

            let desiredWidth = configuration.resolution.width
            let desiredHeight = configuration.resolution.height
            let desiredFPS = configuration.frameRate.value

            // Find best format matching desired resolution + frame rate
            var bestFormat: AVCaptureDevice.Format?
            var bestResolutionDiff = Int.max

            for format in device.formats {
                let desc = format.formatDescription
                let dims = CMVideoFormatDescriptionGetDimensions(desc)
                let w = Int(dims.width)
                let h = Int(dims.height)
                let diff = abs(w - desiredWidth) + abs(h - desiredHeight)

                // Only consider formats that support the desired FPS
                for range in format.videoSupportedFrameRateRanges
                where range.minFrameRate <= desiredFPS
                    && range.maxFrameRate >= desiredFPS
                {
                    // Also check multi-cam support
                    if format.isMultiCamSupported && diff < bestResolutionDiff {
                        bestResolutionDiff = diff
                        bestFormat = format
                    }
                }
            }

            // Fallback: any multi-cam format at any FPS
            if bestFormat == nil {
                for format in device.formats
                where format.isMultiCamSupported {
                    let desc = format.formatDescription
                    let dims = CMVideoFormatDescriptionGetDimensions(desc)
                    let w = Int(dims.width)
                    let h = Int(dims.height)
                    let diff =
                        abs(w - desiredWidth) + abs(h - desiredHeight)
                    if diff < bestResolutionDiff {
                        bestResolutionDiff = diff
                        bestFormat = format
                    }
                }
            }

            if let format = bestFormat {
                device.activeFormat = format
                device.activeVideoMinFrameDuration = CMTime(
                    value: 1, timescale: CMTimeScale(desiredFPS))
                device.activeVideoMaxFrameDuration = CMTime(
                    value: 1, timescale: CMTimeScale(desiredFPS))
                let dims = CMVideoFormatDescriptionGetDimensions(
                    format.formatDescription)
                print(
                    "📷 [MultiCam] Device \(device.localizedName) format: \(dims.width)x\(dims.height) @ \(desiredFPS)fps (multiCamSupported)"
                )
            }
        }

        private static func extractSample(
            from sampleBuffer: CMSampleBuffer,
            configuration: VideoSourceConfiguration
        ) -> CapturedVideoSample? {
            guard
                let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else { return nil }

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            }

            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

            guard
                let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            else { return nil }

            let data = Data(
                bytes: baseAddress, count: bytesPerRow * height)
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

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

    /// Delegate to receive video sample buffers in multi-cam sessions.
    ///
    /// @unchecked Sendable justification: This class is only used as a delegate
    /// on a serial DispatchQueue. The handler closure is @Sendable. The class
    /// has no mutable state accessed from multiple threads.
    @available(iOS 17.0, *)
    private final class MultiCamOutputDelegate: NSObject,
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
#endif
