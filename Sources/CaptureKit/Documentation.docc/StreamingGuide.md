# Streaming

Build live streaming pipelines with capture, encoding, and transport.

## Overview

``StreamingPipeline`` provides a unified capture → encode → send pipeline
that captures from audio and/or video sources, encodes raw buffers, and
delivers ``MediaPacket`` values to any ``StreamingTransport`` implementation.

## Pipeline modes

| Mode | Description |
|------|-------------|
| `.audioOnly` | Single audio source + encoder |
| `.videoOnly` | Single video source + encoder |
| `.muxed` | Audio + video interleaved through a shared channel |

## Audio-only streaming

Stream audio from a microphone to a transport:

```swift
let pipeline = StreamingPipeline(
    mode: .audioOnly(
        source: MicrophoneSource(),
        encoder: AACEncoder(configuration: .podcast)
    ),
    transport: myTransport
)
try await pipeline.start()
```

## Muxed audio + video

In `.muxed` mode, the pipeline waits for the first video keyframe,
extracts codec parameter sets (SPS/PPS for H.264, VPS/SPS/PPS for HEVC),
and sends configuration via ``StreamingTransport/sendConfiguration(_:)``
before delivering interleaved packets:

```swift
let pipeline = StreamingPipeline(
    mode: .muxed(
        videoSource: CameraSource(),
        videoEncoder: H264Encoder(configuration: .streaming1080p),
        audioSource: MicrophoneSource(),
        audioEncoder: AACEncoder(configuration: .podcast)
    ),
    transport: myTransport
)
try await pipeline.start()
```

## Transport protocol

``StreamingTransport`` defines the interface for sending encoded media
to remote endpoints:

```swift
public protocol StreamingTransport: Sendable {
    func connect() async throws
    func sendConfiguration(_ config: StreamConfiguration) async throws
    func send(_ packet: MediaPacket) async throws
    func disconnect() async throws
}
```

Concrete implementations live in consuming apps or bridge packages.
See <doc:StreamingIntegration> for RTMP, SRT, HLS, and Icecast examples.

## Pipeline statistics

Monitor streaming health via ``StreamingPipeline/stats``:

```swift
let stats = await pipeline.stats
print("Sent: \(stats.bytesSent) bytes, FPS: \(stats.videoFPS)")
```

## Stop streaming

```swift
await pipeline.stop()
```

This cancels producers, finishes the mux channel, and disconnects
the transport.

## Next Steps

- <doc:StreamingIntegration> — Connect to RTMP, SRT, HLS, and Icecast
- <doc:PresetsGuide> — Platform-specific streaming presets (Twitch, YouTube)
- <doc:Encoding> — Encoder configuration for streaming
