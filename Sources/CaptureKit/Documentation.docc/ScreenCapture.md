# Screen Capture

Capture screen content on macOS and iOS.

## Overview

CaptureKit supports screen capture through two Apple frameworks:
**ScreenCaptureKit** (macOS 14+) for high-performance screen recording,
and **ReplayKit** (iOS 17+) for in-app and broadcast capture.

## Screen capture on macOS

``ScreenCaptureSource`` wraps ScreenCaptureKit and supports multiple
capture modes via ``ScreenCaptureMode``:

- **Full screen** — capture the entire display
- **Window** — capture a specific window
- **Region** — capture a rectangular area
- **App exclusion** — capture everything except specified apps

```swift
let source = ScreenCaptureSource()
let config = VideoSourceConfiguration(
    resolution: .p1080,
    frameRate: .fps30
)
try await source.configure(config)
```

Screen capture requires the `screenRecording` permission. Use
``PermissionManager`` to request it before starting capture.

## Screen capture on iOS

On iOS, screen capture uses ReplayKit for in-app recording or
broadcast extensions.

## System audio with screen capture

On macOS, system audio capture is available alongside screen recording
via ``SystemAudioSource`` with source type `.systemAudio`. This captures
the audio output of the system or specific applications.

## Next Steps

- <doc:PermissionsGuide> — Request screen recording permission
- <doc:VideoCapture> — Camera-based video capture
- <doc:OutputsGuide> — Record screen capture to file or stream
