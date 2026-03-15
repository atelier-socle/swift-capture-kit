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
    ///
    /// For codecs with a fixed frame size (e.g. AAC-LC = 1024 samples),
    /// incoming PCM buffers are accumulated internally and fed to the
    /// converter in exact multiples of `mFramesPerPacket`. This decouples
    /// the capture buffer size (e.g. 960 samples at 20 ms / 48 kHz) from
    /// the codec frame size, preventing `-10877` (insufficient input) errors.
    @available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
    actor AudioToolboxEncoder: AudioEncoderProviding {

        private var audioConverter: AudioConverterRef?
        private var outputASBD: AudioStreamBasicDescription?
        private var inputASBD: AudioStreamBasicDescription?

        /// PCM sample accumulator. Bridges the gap between the capture
        /// buffer size and the codec frame size (e.g. 960 vs 1024 for
        /// AAC-LC at 48 kHz / 20 ms buffers).
        private var pcmAccumulator = Data()

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

            pcmAccumulator = Data()

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
        ) async throws -> (Data, packetSizes: [Int]?) {
            guard let converter = audioConverter,
                let inASBD = inputASBD,
                let outASBD = outputASBD
            else {
                throw CaptureError.encodingFailed(
                    codec: "audio",
                    reason: "Encoder not configured"
                )
            }

            let bytesPerFrame = Int(inASBD.mBytesPerFrame)
            guard bytesPerFrame > 0 else {
                throw CaptureError.encodingFailed(
                    codec: "audio",
                    reason: "Invalid input format"
                )
            }

            let framesPerPacket = Int(outASBD.mFramesPerPacket)

            // Codecs without a fixed frame size (PCM, etc.) — pass
            // through directly, no accumulation needed.
            if framesPerPacket <= 1 {
                return try encodeDirect(
                    converter: converter,
                    inputASBD: inASBD,
                    outputASBD: outASBD,
                    data: data
                )
            }

            // Accumulate incoming PCM samples.
            pcmAccumulator.append(data)

            let bytesPerPacket = framesPerPacket * bytesPerFrame

            // Not enough samples for a single codec frame yet.
            guard pcmAccumulator.count >= bytesPerPacket else {
                return (Data(), packetSizes: nil)
            }

            // Encode as many complete frames as possible.
            var encodedOutput = Data()
            var allPacketSizes: [Int] = []

            while pcmAccumulator.count >= bytesPerPacket {
                let chunk = Data(pcmAccumulator.prefix(bytesPerPacket))
                pcmAccumulator.removeFirst(bytesPerPacket)

                let (encoded, sizes) = try encodeExactFrame(
                    converter: converter,
                    inputASBD: inASBD,
                    outputASBD: outASBD,
                    data: chunk,
                    frameCount: framesPerPacket
                )

                if !encoded.isEmpty {
                    encodedOutput.append(encoded)
                    if let sizes {
                        allPacketSizes.append(contentsOf: sizes)
                    }
                }
            }

            if encodedOutput.isEmpty {
                return (Data(), packetSizes: nil)
            }

            return (
                encodedOutput,
                packetSizes: allPacketSizes.isEmpty
                    ? nil : allPacketSizes
            )
        }

        func flush() async throws -> Data? {
            nil
        }

        func reset() async {
            if let converter = audioConverter {
                AudioConverterReset(converter)
            }
            pcmAccumulator = Data()
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
            pcmAccumulator = Data()
        }

        // MARK: - Encoding

        /// Encode exactly `framesPerPacket` PCM frames into one codec
        /// packet. Used by the accumulation path.
        private func encodeExactFrame(
            converter: AudioConverterRef,
            inputASBD: AudioStreamBasicDescription,
            outputASBD: AudioStreamBasicDescription,
            data: Data,
            frameCount: Int
        ) throws -> (Data, packetSizes: [Int]?) {
            try data.withUnsafeBytes { rawInput in
                guard let baseAddress = rawInput.baseAddress
                else {
                    return (Data(), packetSizes: nil)
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

        /// Direct encode without accumulation — for codecs that have no
        /// fixed frame size (e.g. Linear PCM).
        private func encodeDirect(
            converter: AudioConverterRef,
            inputASBD: AudioStreamBasicDescription,
            outputASBD: AudioStreamBasicDescription,
            data: Data
        ) throws -> (Data, packetSizes: [Int]?) {
            let bytesPerFrame = Int(inputASBD.mBytesPerFrame)
            let frameCount = data.count / bytesPerFrame

            return try data.withUnsafeBytes { rawInput in
                guard let baseAddress = rawInput.baseAddress
                else {
                    return (Data(), packetSizes: nil)
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
        ) throws -> (Data, packetSizes: [Int]?) {
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

            // Status 1 = our "input exhausted" sentinel (normal).
            // Status -10877 = not enough input data for a complete
            // codec frame. With the PCM accumulator this should only
            // happen on the very first call while the converter primes.
            if status == -10877 {
                return (Data(), packetSizes: nil)
            }
            guard status == noErr || status == 1 else {
                throw CaptureError.encodingFailed(
                    codec: "audio",
                    reason:
                        "AudioConverterFillComplexBuffer failed: \(status)"
                )
            }

            let produced = Int(
                outputBufferList.mBuffers.mDataByteSize)
            let outputData = Data(bytes: outputPtr, count: produced)

            // Extract per-packet sizes from packet descriptions.
            var sizes: [Int]?
            if let descs = packetDescs, outputPacketCount > 0 {
                sizes = (0..<Int(outputPacketCount)).map { i in
                    Int(descs[i].mDataByteSize)
                }
            }

            return (outputData, packetSizes: sizes)
        }
    }
#endif
