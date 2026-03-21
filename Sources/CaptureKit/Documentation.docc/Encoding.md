# Encoding

Encode audio and video with every Apple-supported codec.

## Overview

CaptureKit provides encoder actors for all Apple-supported audio and video
codecs. Audio encoders conform to ``AudioEncoderProtocol``, video encoders
to ``VideoEncoderProtocol``. All encoders are actors with a consistent
configure → encode → flush → reset lifecycle.

## Audio encoders

| Encoder | Codec | Hardware | Use Case |
|---------|-------|----------|----------|
| ``AACEncoder`` | `.aac` | Yes | Streaming, podcasts |
| ``ALACEncoder`` | `.alac` | No | Lossless Apple ecosystem |
| ``OpusEncoder`` | `.opus` | No | Low-latency, WebRTC |
| ``FLACEncoder`` | `.flac` | No | Lossless archival |
| ``WAVEncoder`` | `.pcm` | No | Uncompressed recording |
| ``PCMEncoder`` | `.pcm` | No | Raw PCM passthrough |
| ``MP3Encoder`` | `.mp3` | No | Web radio (macOS only) |

## Video encoders

| Encoder | Codec | Hardware | Use Case |
|---------|-------|----------|----------|
| ``H264Encoder`` | `.h264` | Yes | Universal streaming |
| ``HEVCEncoder`` | `.hevc` | Yes | 4K, HDR |
| ``ProResEncoder`` | `.prores` | Yes | Professional editing |
| ``AV1Encoder`` | `.av1` | Yes | Next-gen streaming |
| ``MVHEVCEncoder`` | `.mvHevc` | Yes | Spatial video (visionOS) |
| ``JPEGEncoder`` | `.jpeg` | Yes | Frame-by-frame capture |

## Encoder lifecycle

All encoders follow the same pattern:

```swift
let encoder = AACEncoder(configuration: .podcast)

// 1. Configure
try await encoder.configure(aac: .podcast)

// 2. Encode buffers
let encoded = try await encoder.encode(buffer)

// 3. Flush remaining data
let remaining = try await encoder.flush()

// 4. Reset for reuse
await encoder.reset()
```

## Codec-specific configuration

Each encoder has a dedicated configuration type with presets:

```swift
// AAC with podcast preset
let aac = AACEncoder(configuration: .podcast)

// H.264 for streaming
let h264 = H264Encoder(configuration: .streaming1080p)

// HEVC with HDR
let hevc = HEVCEncoder(configuration: .hdr4K)

// ProRes for archival
let prores = ProResEncoder(configuration: .hq)
```

## Generic configuration

All encoders also accept the generic ``AudioEncoderConfiguration`` or
``VideoEncoderConfiguration`` through the protocol-level `configure` method:

```swift
let config = AudioEncoderConfiguration(
    bitrate: 128_000,
    sampleRate: .rate48000,
    channelCount: 2
)
try await encoder.configure(config)
```

## Configuration validation

Codec-specific configurations provide a `validate()` method that throws
before the encoder is initialized:

```swift
let config = H264EncoderConfiguration(
    profile: .baseline,
    entropyMode: .cabac  // Invalid: baseline doesn't support CABAC
)
try config.validate()  // Throws CaptureError
```

## Dynamic bitrate updates

Video encoders support runtime bitrate changes for adaptive streaming:

```swift
try await videoEncoder.updateBitrate(2_500_000)
try await videoEncoder.forceKeyFrame()
```

## Next Steps

- <doc:PresetsGuide> — Ready-made configurations for common scenarios
- <doc:OutputsGuide> — Deliver encoded media to files or streams
- <doc:StreamingGuide> — Build live streaming pipelines
