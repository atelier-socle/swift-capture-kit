// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if canImport(ReplayKit) && os(iOS)
    @preconcurrency import ReplayKit
    import Foundation

    /// Real screen video capture using ReplayKit RPScreenRecorder (iOS only).
    ///
    /// Actor isolation protects RPScreenRecorder access.
    /// Captures the current app's screen content as video frames.
    @available(iOS 17.0, *)
    actor ReplayKitVideoProvider: ScreenCaptureVideoProviding {
        private var isRecording = false

        func startCapture(
            mode: ScreenCaptureMode
        ) async throws -> AsyncStream<CapturedVideoSample> {
            guard case .replayKit = mode else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "screenCapture",
                    reason: "ReplayKitVideoProvider requires .replayKit mode"
                )
            }

            let recorder = RPScreenRecorder.shared()
            guard recorder.isAvailable else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "screenCapture",
                    reason: "ReplayKit screen recorder is not available"
                )
            }

            isRecording = true

            return AsyncStream { continuation in
                recorder.startCapture { sampleBuffer, sampleBufferType, error in
                    guard error == nil, sampleBufferType == .video else { return }
                    if let sample = Self.extractSample(from: sampleBuffer) {
                        continuation.yield(sample)
                    }
                }

                continuation.onTermination = { _ in
                    recorder.stopCapture { _ in }
                }
            }
        }

        func stopCapture() async {
            guard isRecording else { return }
            isRecording = false
            let recorder = RPScreenRecorder.shared()
            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                recorder.stopCapture { _ in
                    cont.resume()
                }
            }
        }

        private static func extractSample(
            from sampleBuffer: CMSampleBuffer
        ) -> CapturedVideoSample? {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else { return nil }

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

            guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            else { return nil }

            let data = Data(bytes: baseAddress, count: bytesPerRow * height)
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

            let format = VideoFormat(
                resolution: .custom(width: width, height: height),
                frameRate: .fps30,
                pixelFormat: .bgra,
                colorSpace: .srgb,
                dynamicRange: .sdr
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
