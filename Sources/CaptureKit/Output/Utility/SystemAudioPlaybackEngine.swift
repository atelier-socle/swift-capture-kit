// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if canImport(AVFAudio)
    @preconcurrency import AVFAudio
    import Foundation

    /// Real audio playback engine using AVAudioEngine for monitoring.
    ///
    /// Actor isolation protects the non-Sendable AVAudioEngine.
    @available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
    actor SystemAudioPlaybackEngine: AudioPlaybackProviding {
        private var audioEngine: AVAudioEngine?
        private var playerNode: AVAudioPlayerNode?
        private var playbackFormat: AVAudioFormat?
        private var savedVolume: Float = 1.0

        func prepare(format: AudioFormat) async throws {
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)

            guard
                let avFormat = AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: format.sampleRate.rawValue,
                    channels: AVAudioChannelCount(format.channelCount),
                    interleaved: format.isInterleaved
                )
            else {
                throw CaptureError.outputPrepareFailed(
                    outputID: "audio-preview",
                    reason: "Cannot create AVAudioFormat for monitoring"
                )
            }
            engine.connect(
                player, to: engine.mainMixerNode, format: avFormat)
            try engine.start()
            player.play()

            self.audioEngine = engine
            self.playerNode = player
            self.playbackFormat = avFormat
        }

        func play(_ data: Data) async throws {
            guard let player = playerNode,
                let format = playbackFormat
            else { return }

            let bytesPerFrame =
                Int(format.channelCount)
                * MemoryLayout<Float>.size
            guard bytesPerFrame > 0 else { return }
            let frameCount = AVAudioFrameCount(
                data.count / bytesPerFrame)
            guard frameCount > 0 else { return }

            guard
                let buffer = AVAudioPCMBuffer(
                    pcmFormat: format,
                    frameCapacity: frameCount)
            else { return }
            buffer.frameLength = frameCount

            data.withUnsafeBytes { ptr in
                guard let src = ptr.baseAddress,
                    let dst = buffer.floatChannelData?[0]
                else { return }
                dst.update(
                    from: src.assumingMemoryBound(to: Float.self),
                    count: Int(frameCount) * Int(format.channelCount))
            }
            await player.scheduleBuffer(buffer)
        }

        func setVolume(_ volume: Float) async {
            savedVolume = volume
            playerNode?.volume = volume
        }

        func setMuted(_ muted: Bool) async {
            playerNode?.volume = muted ? 0 : savedVolume
        }

        func stop() async {
            playerNode?.stop()
            audioEngine?.stop()
            audioEngine = nil
            playerNode = nil
            playbackFormat = nil
        }
    }
#endif
