// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("CameraSource with DI")
struct CameraSourceIntegrationTests {

    private func makeSample(
        timestamp: TimeInterval = 0.0
    ) -> CapturedVideoSample {
        CapturedVideoSample(
            data: Data(repeating: 0xAB, count: 1920 * 1080 * 4),
            timestamp: timestamp,
            format: VideoFormat(
                resolution: .p1080,
                frameRate: .fps30,
                pixelFormat: .bgra,
                colorSpace: .bt709,
                dynamicRange: .sdr
            ),
            isKeyFrame: true
        )
    }

    @Test("startCapture calls engine startCapture")
    func startCaptureCallsEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CameraSource(captureEngine: engine)
        _ = try await source.startCapture()
        let count = await engine.startCallCount
        #expect(count == 1)
    }

    @Test("stopCapture calls engine stopCapture")
    func stopCaptureCallsEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CameraSource(captureEngine: engine)
        _ = try await source.startCapture()
        await source.stopCapture()
        let count = await engine.stopCallCount
        #expect(count == 1)
    }

    @Test("produces VideoFrame from CapturedVideoSample")
    func producesVideoFrame() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let sample = makeSample(timestamp: 1.5)
        await engine.setSamples([sample])
        let source = CameraSource(captureEngine: engine)
        let stream = try await source.startCapture()
        var frames: [VideoFrame] = []
        for await frame in stream {
            frames.append(frame)
        }
        #expect(frames.count == 1)
        #expect(frames[0].timestamp == 1.5)
        #expect(frames[0].isKeyFrame == true)
    }

    @Test("passes position to engine")
    func passesPositionToEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CameraSource(position: .front, captureEngine: engine)
        _ = try await source.startCapture()
        let pos = await engine.lastPosition
        #expect(pos == .front)
    }

    @Test("passes deviceType to engine")
    func passesDeviceTypeToEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CameraSource(captureEngine: engine)
        _ = try await source.startCapture()
        let dt = await engine.lastDeviceType
        #expect(dt == .wideAngle)
    }

    @Test("switchCamera delegates to engine")
    func switchCameraDelegatesToEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CameraSource(captureEngine: engine)
        try await source.switchCamera(to: .front)
        let count = await engine.switchCameraCallCount
        #expect(count == 1)
    }

    @Test("switchCamera updates position property")
    func switchCameraUpdatesPosition() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CameraSource(captureEngine: engine)
        let initial = await source.position
        #expect(initial == .back)
        try await source.switchCamera(to: .front)
        let updated = await source.position
        #expect(updated == .front)
    }

    @Test("capturePhoto delegates to engine and returns photo")
    func capturePhotoDelegatesToEngine() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        let source = CameraSource(captureEngine: engine)
        let photo = try await source.capturePhoto()
        #expect(photo.format == .jpeg)
        #expect(photo.data.count > 0)
    }

    @Test("sequential frames have incrementing sequence numbers")
    func sequentialFramesHaveIncrementingSequenceNumbers() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        await engine.setSamples([
            makeSample(timestamp: 0.0),
            makeSample(timestamp: 0.033),
            makeSample(timestamp: 0.066)
        ])
        let source = CameraSource(captureEngine: engine)
        let stream = try await source.startCapture()
        var seqs: [Int64] = []
        for await frame in stream {
            seqs.append(frame.sequenceNumber)
        }
        #expect(seqs == [0, 1, 2])
    }

    @Test("engine error propagates on startCapture")
    func engineErrorPropagates() async throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }
        let engine = MockVideoCaptureEngine()
        await engine.setThrowOnStart(true)
        let source = CameraSource(captureEngine: engine)
        await #expect(throws: CaptureError.self) {
            _ = try await source.startCapture()
        }
    }
}

// MARK: - MockVideoCaptureEngine helpers

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension MockVideoCaptureEngine {
    func setSamples(_ samples: [CapturedVideoSample]) {
        self.syntheticSamples = samples
    }

    func setThrowOnStart(_ value: Bool) {
        self.shouldThrowOnStart = value
    }
}
