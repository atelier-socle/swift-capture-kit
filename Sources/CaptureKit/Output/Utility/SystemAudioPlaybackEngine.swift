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
        deinit {
            audioEngine?.stop()
        }

        private var audioEngine: AVAudioEngine?
        private var playerNode: AVAudioPlayerNode?
        private var playbackFormat: AVAudioFormat?
        private var savedVolume: Float = 1.0
        private var inputChannelCount: Int = 1
        private var inputIsInterleaved: Bool = true

        func prepare(format: AudioFormat) async throws {
            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)

            // AVAudioEngine always uses non-interleaved format for
            // internal node connections. Using interleaved: true crashes
            // with kAudioUnitErr_FormatNotSupported (-10868).
            guard
                let avFormat = AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: format.sampleRate.rawValue,
                    channels: AVAudioChannelCount(format.channelCount),
                    interleaved: false
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
            self.inputChannelCount = format.channelCount
            self.inputIsInterleaved = format.isInterleaved
        }

        func play(_ data: Data) async throws {
            guard let player = playerNode,
                let format = playbackFormat
            else { return }

            let channelCount = Int(format.channelCount)
            let bytesPerFrame = channelCount * MemoryLayout<Float>.size
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
                guard let src = ptr.baseAddress else { return }
                let samples = src.assumingMemoryBound(to: Float.self)

                if channelCount > 1 && inputIsInterleaved {
                    // De-interleave: [L0, R0, L1, R1, ...] →
                    // channel0=[L0, L1, ...], channel1=[R0, R1, ...]
                    for frame in 0..<Int(frameCount) {
                        for ch in 0..<channelCount {
                            buffer.floatChannelData?[ch][frame] =
                                samples[frame * channelCount + ch]
                        }
                    }
                } else {
                    // Mono or already non-interleaved: copy directly
                    guard let dst = buffer.floatChannelData?[0]
                    else { return }
                    dst.update(
                        from: samples,
                        count: Int(frameCount) * channelCount)
                }
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
