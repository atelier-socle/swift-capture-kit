// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if canImport(ScreenCaptureKit)
    @preconcurrency import ScreenCaptureKit
    import Foundation

    /// Real screen video capture using ScreenCaptureKit SCStream (macOS only).
    ///
    /// Actor isolation protects the non-Sendable SCStream.
    /// Captures display, window, or application content as video frames.
    @available(macOS 14.0, *)
    actor SCStreamVideoProvider: ScreenCaptureVideoProviding {
        private var stream: SCStream?
        private var delegate: SCStreamVideoDelegate?

        func startCapture(
            mode: ScreenCaptureMode
        ) async throws -> AsyncStream<CapturedVideoSample> {
            guard case .screenCaptureKit(let target) = mode else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "screenCapture",
                    reason: "SCStreamVideoProvider requires .screenCaptureKit mode"
                )
            }

            let content = try await SCShareableContent.current

            let configuration = SCStreamConfiguration()
            configuration.capturesAudio = false

            let filter = try buildFilter(target: target, content: content)

            if let display = content.displays.first {
                configuration.width = display.width
                configuration.height = display.height
            }

            let scStream = SCStream(
                filter: filter,
                configuration: configuration,
                delegate: nil)
            self.stream = scStream

            let streamDelegate = SCStreamVideoDelegate()
            self.delegate = streamDelegate

            try scStream.addStreamOutput(
                streamDelegate,
                type: .screen,
                sampleHandlerQueue: DispatchQueue(
                    label: "com.atelier-socle.capturekit.scstream.video"))

            try await scStream.startCapture()

            let sampleStream = streamDelegate.samples
            return AsyncStream { continuation in
                let task = Task {
                    for await sample in sampleStream {
                        continuation.yield(sample)
                    }
                    continuation.finish()
                }
                continuation.onTermination = { [weak self] _ in
                    task.cancel()
                    Task { await self?.stopCapture() }
                }
            }
        }

        func stopCapture() async {
            try? await stream?.stopCapture()
            stream = nil
            delegate = nil
        }

        // MARK: - Private

        private func buildFilter(
            target: ScreenCaptureKitTarget,
            content: SCShareableContent
        ) throws -> SCContentFilter {
            guard let display = content.displays.first else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "screenCapture",
                    reason: "No display found"
                )
            }

            switch target {
            case .display:
                return SCContentFilter(
                    display: display,
                    excludingApplications: [],
                    exceptingWindows: [])

            case .window(let windowID):
                if let window = content.windows.first(
                    where: { $0.windowID == windowID })
                {
                    return SCContentFilter(
                        desktopIndependentWindow: window)
                }
                return SCContentFilter(
                    display: display,
                    excludingApplications: [],
                    exceptingWindows: [])

            case .application(let bundleID):
                let apps = content.applications.filter {
                    $0.bundleIdentifier == bundleID
                }
                return SCContentFilter(
                    display: display,
                    including: apps,
                    exceptingWindows: [])

            case .region:
                return SCContentFilter(
                    display: display,
                    excludingApplications: [],
                    exceptingWindows: [])
            }
        }
    }

    /// @unchecked Sendable justification: This class is only used as a delegate
    /// on a serial DispatchQueue. The continuation is thread-safe. The class
    /// has no mutable state accessed from multiple threads.
    @available(macOS 14.0, *)
    private final class SCStreamVideoDelegate: NSObject, SCStreamOutput,
        @unchecked Sendable
    {
        private let continuation: AsyncStream<CapturedVideoSample>.Continuation
        let samples: AsyncStream<CapturedVideoSample>

        override init() {
            let (stream, cont) = AsyncStream.makeStream(
                of: CapturedVideoSample.self)
            self.samples = stream
            self.continuation = cont
            super.init()
        }

        func stream(
            _ stream: SCStream,
            didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
            of type: SCStreamOutputType
        ) {
            guard type == .screen else { return }
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else { return }

            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

            guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
            else { return }

            let data = Data(bytes: baseAddress, count: bytesPerRow * height)
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

            let format = VideoFormat(
                resolution: .custom(width: width, height: height),
                frameRate: .fps30,
                pixelFormat: .bgra,
                colorSpace: .srgb,
                dynamicRange: .sdr
            )

            let sample = CapturedVideoSample(
                data: data,
                timestamp: CMTimeGetSeconds(pts),
                format: format,
                isKeyFrame: true
            )
            continuation.yield(sample)
        }
    }
#endif
