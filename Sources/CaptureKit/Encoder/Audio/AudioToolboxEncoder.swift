// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

#if canImport(AudioToolbox)
    import AudioToolbox
    import Foundation

    /// Context passed to the AudioConverter input callback.
    private struct EncoderInputContext {
        var buffer: UnsafeRawPointer
        var byteSize: UInt32
        var packetCount: UInt32
        var bytesPerPacket: UInt32
        var consumed: Bool
    }

    /// C callback for AudioConverterFillComplexBuffer.
    ///
    /// Provides PCM input data to the converter on demand.
    /// Returns `noErr` on first call (providing data),
    /// then returns 1 on subsequent calls (input exhausted).
    private let audioConverterInputProc: AudioConverterComplexInputDataProc = { _, ioNumberDataPackets, ioData, outPacketDescriptions, inUserData in
        guard
            let context = inUserData?.assumingMemoryBound(
                to: EncoderInputContext.self
            )
        else {
            ioNumberDataPackets.pointee = 0
            return 1
        }

        if context.pointee.consumed {
            ioNumberDataPackets.pointee = 0
            return 1
        }

        ioNumberDataPackets.pointee = context.pointee.packetCount
        ioData.pointee.mNumberBuffers = 1
        ioData.pointee.mBuffers.mData = UnsafeMutableRawPointer(
            mutating: context.pointee.buffer)
        ioData.pointee.mBuffers.mDataByteSize =
            context.pointee.byteSize
        ioData.pointee.mBuffers.mNumberChannels = 1

        // PCM has no packet descriptions
        outPacketDescriptions?.pointee = nil

        context.pointee.consumed = true
        return noErr
    }

    /// Real audio encoder using AudioToolbox AudioConverter.
    ///
    /// Supports: AAC (all profiles), ALAC, Opus, FLAC, MP3.
    /// PCM is passthrough (no converter needed).
    /// Actor isolation protects the non-Sendable AudioConverterRef.
    @available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
    actor AudioToolboxEncoder: AudioEncoderProviding {

        private var audioConverter: AudioConverterRef?
        private var outputASBD: AudioStreamBasicDescription?
        private var inputASBD: AudioStreamBasicDescription?

        func configure(
            inputFormat: AudioFormat,
            outputCodec: AudioCodec,
            bitrate: Int?,
            sampleRate: SampleRate,
            channelCount: Int
        ) async throws {
            // Dispose existing converter if any
            if let existing = audioConverter {
                AudioConverterDispose(existing)
                audioConverter = nil
            }

            // Build input ASBD (Linear PCM Float32)
            var inASBD = AudioStreamBasicDescription(
                mSampleRate: inputFormat.sampleRate.rawValue,
                mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: kAudioFormatFlagIsFloat
                    | kAudioFormatFlagIsPacked,
                mBytesPerPacket: UInt32(inputFormat.channelCount * 4),
                mFramesPerPacket: 1,
                mBytesPerFrame: UInt32(inputFormat.channelCount * 4),
                mChannelsPerFrame: UInt32(inputFormat.channelCount),
                mBitsPerChannel: 32,
                mReserved: 0
            )

            // Build output ASBD
            var outASBD = AudioStreamBasicDescription()
            outASBD.mSampleRate = sampleRate.rawValue
            outASBD.mChannelsPerFrame = UInt32(channelCount)
            outASBD.mFormatID = formatID(for: outputCodec)

            // Let AudioToolbox fill in format details
            var size = UInt32(
                MemoryLayout<AudioStreamBasicDescription>.size)
            AudioFormatGetProperty(
                kAudioFormatProperty_FormatInfo,
                0, nil,
                &size, &outASBD
            )

            // Create converter
            var converter: AudioConverterRef?
            let status = AudioConverterNew(
                &inASBD, &outASBD, &converter)
            guard status == noErr, let converter else {
                throw CaptureError.encoderConfigurationFailed(
                    codec: outputCodec.rawValue,
                    reason:
                        "AudioConverterNew failed with status \(status)"
                )
            }

            // Set bitrate if applicable
            if let bitrate {
                var bitrateValue = UInt32(bitrate)
                AudioConverterSetProperty(
                    converter,
                    kAudioConverterEncodeBitRate,
                    UInt32(MemoryLayout<UInt32>.size),
                    &bitrateValue
                )
            }

            self.audioConverter = converter
            self.inputASBD = inASBD
            self.outputASBD = outASBD
        }

        func encode(
            data: Data, timestamp: TimeInterval
        ) async throws -> Data {
            guard let converter = audioConverter,
                let inASBD = inputASBD,
                let outASBD = outputASBD
            else {
                throw CaptureError.encodingFailed(
                    codec: "audio",
                    reason: "Encoder not configured"
                )
            }

            return try encodeWithConverter(
                converter: converter,
                inputASBD: inASBD,
                outputASBD: outASBD,
                data: data
            )
        }

        func flush() async throws -> Data? {
            nil
        }

        func reset() async {
            if let converter = audioConverter {
                AudioConverterReset(converter)
            }
        }

        private func formatID(for codec: AudioCodec) -> AudioFormatID {
            switch codec {
            case .aac: kAudioFormatMPEG4AAC
            case .alac: kAudioFormatAppleLossless
            case .opus: kAudioFormatOpus
            case .flac: kAudioFormatFLAC
            case .pcm: kAudioFormatLinearPCM
            case .mp3: kAudioFormatMPEGLayer3
            }
        }

        /// Disposes the AudioConverter.
        func dispose() {
            if let converter = audioConverter {
                AudioConverterDispose(converter)
                audioConverter = nil
            }
        }

        // MARK: - Encoding

        private func encodeWithConverter(
            converter: AudioConverterRef,
            inputASBD: AudioStreamBasicDescription,
            outputASBD: AudioStreamBasicDescription,
            data: Data
        ) throws -> Data {
            let bytesPerFrame = Int(inputASBD.mBytesPerFrame)
            guard bytesPerFrame > 0 else {
                throw CaptureError.encodingFailed(
                    codec: "audio",
                    reason: "Invalid input format"
                )
            }
            let frameCount = data.count / bytesPerFrame

            return try data.withUnsafeBytes { rawInput in
                guard let baseAddress = rawInput.baseAddress
                else {
                    return Data()
                }

                var context = EncoderInputContext(
                    buffer: baseAddress,
                    byteSize: UInt32(rawInput.count),
                    packetCount: UInt32(frameCount),
                    bytesPerPacket: inputASBD.mBytesPerPacket,
                    consumed: false
                )

                return try fillOutputBuffer(
                    converter: converter,
                    outputASBD: outputASBD,
                    frameCount: frameCount,
                    inputBufferSize: rawInput.count,
                    context: &context
                )
            }
        }

        private func fillOutputBuffer(
            converter: AudioConverterRef,
            outputASBD: AudioStreamBasicDescription,
            frameCount: Int,
            inputBufferSize: Int,
            context: inout EncoderInputContext
        ) throws -> Data {
            // Output buffer: at least as large as input
            let outputSize = max(inputBufferSize, 32_768)
            let outputPtr = UnsafeMutablePointer<UInt8>.allocate(
                capacity: outputSize)
            defer { outputPtr.deallocate() }

            var outputBufferList = AudioToolbox.AudioBufferList(
                mNumberBuffers: 1,
                mBuffers: AudioToolbox.AudioBuffer(
                    mNumberChannels: outputASBD.mChannelsPerFrame,
                    mDataByteSize: UInt32(outputSize),
                    mData: outputPtr
                )
            )

            var outputPacketCount: UInt32
            if outputASBD.mFramesPerPacket > 0 {
                outputPacketCount = UInt32(
                    frameCount / Int(outputASBD.mFramesPerPacket))
                outputPacketCount = max(outputPacketCount, 1)
            } else {
                outputPacketCount = 1
            }

            // VBR codecs (AAC, Opus, etc.) require output packet descriptions.
            // Linear PCM (mBytesPerPacket > 0) does not.
            let needsPacketDescriptions = outputASBD.mBytesPerPacket == 0
            let packetDescs:
                UnsafeMutablePointer<
                    AudioStreamPacketDescription
                >?
            if needsPacketDescriptions {
                packetDescs = .allocate(
                    capacity: Int(outputPacketCount))
            } else {
                packetDescs = nil
            }
            defer { packetDescs?.deallocate() }

            let status = withUnsafeMutablePointer(
                to: &context
            ) { ctxPtr in
                AudioConverterFillComplexBuffer(
                    converter,
                    audioConverterInputProc,
                    ctxPtr,
                    &outputPacketCount,
                    &outputBufferList,
                    packetDescs
                )
            }

            // Status 1 = our "input exhausted" sentinel (normal)
            guard status == noErr || status == 1 else {
                throw CaptureError.encodingFailed(
                    codec: "audio",
                    reason:
                        "AudioConverterFillComplexBuffer failed: \(status)"
                )
            }

            let produced = Int(
                outputBufferList.mBuffers.mDataByteSize)
            return Data(bytes: outputPtr, count: produced)
        }
    }
#endif
