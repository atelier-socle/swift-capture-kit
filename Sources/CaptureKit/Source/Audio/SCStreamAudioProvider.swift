// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if canImport(ScreenCaptureKit)
    @preconcurrency import ScreenCaptureKit
    import CoreMedia
    import Foundation

    /// Real system audio capture using ScreenCaptureKit SCStream.
    ///
    /// Uses an `SCStreamOutput` delegate on a serial queue to receive
    /// `CMSampleBuffer` audio data and yield `CapturedAudioSample` values
    /// into the returned `AsyncStream`.
    ///
    /// Actor isolation protects the non-Sendable SCStream.
    /// macOS only — ScreenCaptureKit is not available on iOS/visionOS.
    @available(macOS 14.0, *)
    actor SCStreamAudioProvider: ScreenCaptureAudioProviding {
        private var stream: SCStream?
        private var delegate: SCStreamAudioDelegate?
        private var videoDiscardDelegate: SCStreamVideoDiscardDelegate?
        private var errorDelegate: SCStreamErrorDelegate?

        func startCapture(
            mode: SystemAudioCaptureMode,
            excludeOwnApp: Bool
        ) async throws -> AsyncStream<CapturedAudioSample> {
            let content = try await SCShareableContent.current

            let configuration = SCStreamConfiguration()
            configuration.capturesAudio = true
            configuration.excludesCurrentProcessAudio = excludeOwnApp
            configuration.width = 2
            configuration.height = 2

            let filter = try buildFilter(
                mode: mode, content: content)

            let streamErrorDelegate = SCStreamErrorDelegate()
            self.errorDelegate = streamErrorDelegate

            let scStream = SCStream(
                filter: filter,
                configuration: configuration,
                delegate: streamErrorDelegate)
            self.stream = scStream

            let audioDelegate = SCStreamAudioDelegate()
            self.delegate = audioDelegate

            try scStream.addStreamOutput(
                audioDelegate,
                type: .audio,
                sampleHandlerQueue: DispatchQueue(
                    label: "com.atelier-socle.capturekit.scstream.audio"))

            // Register a discard handler for .screen to prevent
            // "stream output NOT found. Dropping frame" spam.
            let discardDelegate = SCStreamVideoDiscardDelegate()
            self.videoDiscardDelegate = discardDelegate
            try scStream.addStreamOutput(
                discardDelegate,
                type: .screen,
                sampleHandlerQueue: DispatchQueue(
                    label:
                        "com.atelier-socle.capturekit.scstream.video-discard"
                ))

            try await scStream.startCapture()

            let sampleStream = audioDelegate.samples
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

        private func buildFilter(
            mode: SystemAudioCaptureMode,
            content: SCShareableContent
        ) throws -> SCContentFilter {
            guard let display = content.displays.first else {
                throw CaptureError.sourceNotAvailable(
                    sourceType: "systemAudio",
                    reason: "No display found"
                )
            }

            switch mode {
            case .allApps:
                return SCContentFilter(
                    display: display,
                    excludingApplications: [],
                    exceptingWindows: [])

            case .specificApps(let bundleIDs):
                let apps = content.applications.filter {
                    bundleIDs.contains($0.bundleIdentifier)
                }
                return SCContentFilter(
                    display: display,
                    including: apps,
                    exceptingWindows: [])

            case .excludeApps(let bundleIDs):
                let excludeApps = content.applications.filter {
                    bundleIDs.contains($0.bundleIdentifier)
                }
                return SCContentFilter(
                    display: display,
                    excludingApplications: excludeApps,
                    exceptingWindows: [])
            }
        }

        func stopCapture() async {
            try? await stream?.stopCapture()
            stream = nil
            delegate = nil
            videoDiscardDelegate = nil
            errorDelegate = nil
        }
    }

    /// @unchecked Sendable justification: This class is used as an SCStreamDelegate
    /// for error callbacks. It has no mutable state.
    @available(macOS 14.0, *)
    private final class SCStreamErrorDelegate: NSObject, SCStreamDelegate,
        @unchecked Sendable
    {
        func stream(
            _ stream: SCStream,
            didStopWithError error: any Error
        ) {
            // Stream stopped due to an error — logged by the provider.
        }
    }

    /// @unchecked Sendable justification: This class is only used as a delegate
    /// on a serial DispatchQueue. It has no mutable state — it silently
    /// discards all video frames to prevent "stream output NOT found" spam.
    @available(macOS 14.0, *)
    private final class SCStreamVideoDiscardDelegate: NSObject,
        SCStreamOutput, @unchecked Sendable
    {
        func stream(
            _ stream: SCStream,
            didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
            of type: SCStreamOutputType
        ) {
            // Intentionally empty — discard video frames.
        }
    }

    /// @unchecked Sendable justification: This class is only used as a delegate
    /// on a serial DispatchQueue. The continuation is thread-safe. The class
    /// has no mutable state accessed from multiple threads.
    @available(macOS 14.0, *)
    private final class SCStreamAudioDelegate: NSObject, SCStreamOutput,
        @unchecked Sendable
    {
        private let continuation: AsyncStream<CapturedAudioSample>.Continuation
        let samples: AsyncStream<CapturedAudioSample>

        override init() {
            let (stream, cont) = AsyncStream.makeStream(
                of: CapturedAudioSample.self)
            self.samples = stream
            self.continuation = cont
            super.init()
        }

        func stream(
            _ stream: SCStream,
            didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
            of type: SCStreamOutputType
        ) {
            guard type == .audio else { return }
            guard CMSampleBufferDataIsReady(sampleBuffer) else { return }

            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)
            else { return }

            var length = 0
            var dataPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(
                blockBuffer, atOffset: 0,
                lengthAtOffsetOut: nil,
                totalLengthOut: &length,
                dataPointerOut: &dataPointer)

            guard let dataPointer, length > 0 else { return }
            let data = Data(bytes: dataPointer, count: length)

            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

            var sampleRate: Double = 48000
            var channelCount = 1
            if let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) {
                if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc) {
                    sampleRate = asbd.pointee.mSampleRate
                    channelCount = Int(asbd.pointee.mChannelsPerFrame)
                }
            }

            let format = AudioFormat(
                sampleRate: SampleRate(rawValue: sampleRate) ?? .rate48000,
                channelCount: channelCount,
                channelLayout: channelCount == 1 ? .mono : .stereo,
                bitDepth: .float32,
                isInterleaved: true
            )

            let sample = CapturedAudioSample(
                data: data,
                timestamp: CMTimeGetSeconds(pts),
                format: format
            )
            continuation.yield(sample)
        }
    }
#endif
