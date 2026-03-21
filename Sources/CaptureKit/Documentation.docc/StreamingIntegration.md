# Streaming Integration

Connect CaptureKit to RTMP, SRT, HLS, and Icecast transports.

## Overview

CaptureKit has no hard dependency on any transport library. The
``StreamingTransport`` protocol defines a minimal interface that bridge
implementations adapt to specific protocols. Concrete bridges live in
consuming apps, keeping CaptureKit transport-agnostic.

## Bridge pattern

A bridge wraps a transport library and conforms to ``StreamingTransport``:

```swift
actor IcecastTransportBridge: StreamingTransport {
    private let client: IcecastClient

    init(client: IcecastClient) {
        self.client = client
    }

    func connect() async throws {
        try await client.connect()
    }

    func sendConfiguration(_ config: StreamConfiguration) async throws {
        // Icecast doesn't use codec configuration packets
    }

    func send(_ packet: MediaPacket) async throws {
        switch packet {
        case .audio(let buffer):
            try await client.send(buffer.data)
        case .video:
            break // Icecast is audio-only
        }
    }

    func disconnect() async throws {
        try await client.disconnect()
    }
}
```

## Companion transport libraries

CaptureKit is designed to work with the Atelier Socle transport ecosystem:

| Library | Protocol | Use Case |
|---------|----------|----------|
| swift-rtmp-kit | RTMP/RTMPS | Twitch, YouTube Live, Facebook Live |
| swift-srt-kit | SRT | Low-latency, reliable transport |
| swift-hls-kit | HLS | Apple-native adaptive streaming |
| swift-icecast-kit | Icecast/SHOUTcast | Internet radio |

## Streaming with RTMP

```swift
// In your app (not in CaptureKit):
let rtmpBridge = RTMPTransportBridge(
    url: "rtmp://live.twitch.tv/app",
    streamKey: streamKey
)

let pipeline = StreamingPipeline(
    mode: .muxed(
        videoSource: CameraSource(),
        videoEncoder: H264Encoder(configuration: .streaming720p),
        audioSource: MicrophoneSource(),
        audioEncoder: AACEncoder(configuration: .podcast)
    ),
    transport: rtmpBridge
)
try await pipeline.start()
```

## Streaming with Icecast (audio-only)

```swift
let icecastBridge = IcecastTransportBridge(client: icecastClient)

let pipeline = StreamingPipeline(
    mode: .audioOnly(
        source: MicrophoneSource(),
        encoder: MP3Encoder(configuration: .webRadio)
    ),
    transport: icecastBridge
)
try await pipeline.start()
```

## Media packet types

The transport receives ``MediaPacket`` values — either `.audio` wrapping
an ``EncodedAudioBuffer`` or `.video` wrapping an ``EncodedVideoFrame``.

Before the first media packets, the pipeline sends ``StreamConfiguration``
with codec parameter sets (H.264 SPS+PPS, HEVC VPS+SPS+PPS) for the
transport to initialize decoders.

## Next Steps

- <doc:StreamingGuide> — StreamingPipeline modes and lifecycle
- <doc:PresetsGuide> — Ready-made presets for Twitch, YouTube, and more
