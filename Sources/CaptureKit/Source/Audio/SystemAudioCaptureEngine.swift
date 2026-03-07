// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

#if canImport(AVFAudio)
    @preconcurrency import AVFAudio
#endif

/// Real audio capture using AVAudioEngine.
///
/// Actor isolation protects the non-Sendable AVAudioEngine.
/// Used by MicrophoneSource, LineInSource, BluetoothAudioSource,
/// VoIPAudioSource, and AggregateAudioSource.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
actor SystemAudioCaptureEngine: AudioCaptureProviding {
    #if canImport(AVFAudio)
        private var audioEngine: AVAudioEngine?
    #endif
    private var _isCapturing = false

    var isCapturing: Bool { _isCapturing }

    func startCapture(
        configuration: AudioSourceConfiguration,
        deviceID: String?
    ) async throws -> AsyncStream<CapturedAudioSample> {
        #if canImport(AVFAudio)
            let engine = AVAudioEngine()

            #if os(iOS) || os(visionOS)
                try Self.configureIOSSession(configuration)
            #endif

            let inputNode = engine.inputNode
            let desiredSampleRate = configuration.sampleRate.rawValue
            let bufferSize = UInt32(
                desiredSampleRate
                    * configuration.preferredBufferDuration)

            self.audioEngine = engine
            self._isCapturing = true

            return AsyncStream { continuation in
                inputNode.installTap(
                    onBus: 0,
                    bufferSize: AVAudioFrameCount(bufferSize),
                    format: nil
                ) { buffer, when in
                    if let sample = Self.convertBuffer(
                        buffer, when: when)
                    {
                        continuation.yield(sample)
                    }
                }

                continuation.onTermination = { [weak self] _ in
                    Task { await self?.stopCapture() }
                }

                do {
                    try engine.start()
                } catch {
                    continuation.finish()
                }
            }
        #else
            throw CaptureError.sourceNotAvailable(
                sourceType: "microphone",
                reason: "AVFAudio not available on this platform"
            )
        #endif
    }

    func stopCapture() async {
        #if canImport(AVFAudio)
            audioEngine?.inputNode.removeTap(onBus: 0)
            audioEngine?.stop()
            audioEngine = nil
            _isCapturing = false

            #if os(iOS) || os(visionOS)
                try? AVAudioSession.sharedInstance().setActive(false)
            #endif
        #endif
    }

    func inputFormat() async -> AudioFormat? {
        #if canImport(AVFAudio)
            guard let engine = audioEngine else { return nil }
            let hwFormat = engine.inputNode.inputFormat(forBus: 0)
            return AudioFormat(
                sampleRate: SampleRate(
                    rawValue: hwFormat.sampleRate) ?? .rate48000,
                channelCount: Int(hwFormat.channelCount),
                channelLayout: hwFormat.channelCount == 1
                    ? .mono : .stereo,
                bitDepth: .float32,
                isInterleaved: hwFormat.isInterleaved
            )
        #else
            return nil
        #endif
    }

    func configureAudioSession(
        category: String, mode: String
    ) async throws {
        #if os(iOS) || os(visionOS)
            let session = AVAudioSession.sharedInstance()
            let avCategory: AVAudioSession.Category =
                category == "playAndRecord"
                ? .playAndRecord : .record
            let avMode: AVAudioSession.Mode =
                mode == "voiceChat" ? .voiceChat : .measurement
            try session.setCategory(avCategory, mode: avMode)
        #endif
    }

    #if canImport(AVFAudio)
        private static func convertBuffer(
            _ buffer: AVAudioPCMBuffer,
            when: AVAudioTime
        ) -> CapturedAudioSample? {
            guard let channelData = buffer.floatChannelData
            else { return nil }
            let frameCount = Int(buffer.frameLength)
            let channelCount = Int(buffer.format.channelCount)

            var interleaved = [Float](
                repeating: 0,
                count: frameCount * channelCount)
            for frame in 0..<frameCount {
                for ch in 0..<channelCount {
                    interleaved[frame * channelCount + ch] =
                        channelData[ch][frame]
                }
            }

            let data = interleaved.withUnsafeBufferPointer { ptr in
                Data(buffer: ptr)
            }

            let format = AudioFormat(
                sampleRate: SampleRate(
                    rawValue: buffer.format.sampleRate)
                    ?? .rate48000,
                channelCount: channelCount,
                channelLayout: channelCount == 1
                    ? .mono : .stereo,
                bitDepth: .float32,
                isInterleaved: true
            )

            return CapturedAudioSample(
                data: data,
                timestamp: Double(when.sampleTime)
                    / buffer.format.sampleRate,
                format: format
            )
        }

        #if os(iOS) || os(visionOS)
            private static func configureIOSSession(
                _ configuration: AudioSourceConfiguration
            ) throws {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(
                    .record, mode: .measurement)
                try session.setPreferredSampleRate(
                    configuration.sampleRate.rawValue)
                try session.setPreferredIOBufferDuration(
                    configuration.preferredBufferDuration)
                try session.setActive(true)
            }
        #endif
    #endif
}
