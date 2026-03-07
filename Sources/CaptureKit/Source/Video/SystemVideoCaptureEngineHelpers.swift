// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if !os(visionOS)
    @preconcurrency import AVFoundation
    import Foundation

    @available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
    extension SystemVideoCaptureEngine {

        func findDevice(
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

        func avCaptureDeviceType(
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

        func sessionPreset(
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

        func pixelFormatType(
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

        func configureDevice(
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
