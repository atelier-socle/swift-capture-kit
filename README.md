# swift-capture-kit

[![CI](https://github.com/atelier-socle/swift-capture-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/atelier-socle/swift-capture-kit/actions/workflows/ci.yml)
[![codecov](https://codecov.io/github/atelier-socle/swift-capture-kit/graph/badge.svg?token=J66F68PISD)](https://codecov.io/github/atelier-socle/swift-capture-kit)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20iPadOS%20|%20visionOS-blue.svg)]()
[![Documentation](https://img.shields.io/badge/Documentation-DocC-blue.svg)](https://atelier-socle.github.io/swift-capture-kit/documentation/capturekit/)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

![swift-capture-kit](./assets/banner.png)

Comprehensive unified media capture library for Apple platforms. Part of the [Atelier Socle](https://www.atelier-socle.com) streaming ecosystem.

## Features

- **Audio capture** — Microphone, line-in, system audio, Bluetooth, aggregate devices, file, VoIP, generators
- **Video capture** — Built-in/external cameras, screen capture, spatial camera, cinematic, multi-camera, file, generators
- **Encoding** — All Apple-supported audio codecs (AAC, ALAC, Opus, FLAC, PCM, MP3) and video codecs (H.264, HEVC, ProRes, AV1, MV-HEVC, JPEG)
- **Outputs** — File recording, streaming, callbacks, sample/pixel buffers, preview, tee
- **Streaming bridge** — Protocol-based `StreamingOutput` for integration with HLS, RTMP, SRT, Icecast
- **Spatial video** — MV-HEVC support for visionOS
- **Adaptive quality** — Automatic bitrate/resolution adjustment based on transport quality
- **Swift 6.2** — Full strict concurrency, actor-based architecture, `Sendable` everywhere
- **Zero dependencies** — Apple frameworks only

## Platform Support

| Platform | Minimum Version | Status |
|----------|----------------|--------|
| macOS    | 14.0           | Full support |
| iOS      | 17.0           | Full support |
| iPadOS   | 17.0           | Full support |
| visionOS | 1.0            | Full support (spatial video) |

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/atelier-socle/swift-capture-kit.git", from: "0.1.0"),
]
```

Then add `CaptureKit` to your target dependencies:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "CaptureKit", package: "swift-capture-kit"),
    ]
),
```

## Quick Start

```swift
import CaptureKit

// Create a capture session
let session = CaptureSession(configuration: .default)

// Check session state
let state = await session.state  // .idle

// Configure audio format
let audioFormat = AudioFormat(
    sampleRate: .rate48000,
    channelCount: 2,
    channelLayout: .stereo
)

// Configure video format
let videoFormat = VideoFormat(
    resolution: .p1080,
    frameRate: .fps30
)
```

## Ecosystem

swift-capture-kit is part of the Atelier Socle streaming ecosystem:

| Library | Description |
|---------|-------------|
| [swift-hls-kit](https://github.com/atelier-socle/swift-hls-kit) | HLS manifest + packaging + live streaming + spatial |
| [swift-icecast-kit](https://github.com/atelier-socle/swift-icecast-kit) | Icecast/SHOUTcast streaming client |
| [swift-rtmp-kit](https://github.com/atelier-socle/swift-rtmp-kit) | RTMP publish client |
| [swift-srt-kit](https://github.com/atelier-socle/swift-srt-kit) | SRT transport (pure Swift) |
| **swift-capture-kit** | **Unified media capture (this library)** |

## License

Apache License 2.0. See [LICENSE](LICENSE) for details.
