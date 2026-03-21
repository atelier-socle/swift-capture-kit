# Getting Started with CaptureKit

Set up CaptureKit and run your first capture session.

## Overview

CaptureKit captures audio and video from Apple platform sources, encodes
with hardware-accelerated codecs, and delivers to outputs — all through a
single ``CaptureSession`` actor.

## Add the dependency

Add CaptureKit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AtelierSocle/swift-capture-kit", from: "0.1.0")
]
```

Then add it to your target:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "CaptureKit", package: "swift-capture-kit")
    ]
)
```

## Record audio to a file

The simplest capture session records microphone audio to an M4A file:

```swift
import CaptureKit

let session = CaptureSession()
session.audioSource = MicrophoneSource()
session.audioEncoder = AACEncoder(configuration: .podcast)

let output = FileOutput(
    url: URL(filePath: "/tmp/recording.m4a"),
    container: .m4a
)
try await session.addOutput(output)
try await session.start()
```

Call ``CaptureSession/stop()`` to end the session and finalize the file.

## Record video with audio

Add a video source and encoder for audio+video recording:

```swift
let session = CaptureSession()
session.audioSource = MicrophoneSource()
session.audioEncoder = AACEncoder(configuration: .podcast)
session.videoSource = CameraSource()
session.videoEncoder = H264Encoder(configuration: .streaming1080p)

let output = FileOutput(
    url: URL(filePath: "/tmp/recording.mp4"),
    container: .mp4
)
try await session.addOutput(output)
try await session.start()
```

## Monitor session events

Subscribe to the ``CaptureSession/events`` stream for real-time updates:

```swift
Task {
    for await event in session.events {
        switch event {
        case .stateChanged(let state):
            print("State: \(state)")
        case .statisticsUpdated(let stats):
            print("Uptime: \(stats.uptime)s")
        default:
            break
        }
    }
}
```

## Use a preset

Platform presets provide ready-made configurations for common scenarios:

```swift
let config = CapturePreset.twitch(resolution: .p720)
let session = CaptureSession.configured(with: config)
```

## Next Steps

- <doc:AudioCapture> — All audio source types and configurations
- <doc:VideoCapture> — Camera, file, and generator sources
- <doc:Encoding> — Audio and video encoder options
- <doc:OutputsGuide> — File, streaming, callback, and preview outputs
- <doc:PermissionsGuide> — Request microphone, camera, and screen permissions
