# Video Capture

Capture video from cameras, files, and generator sources.

## Overview

CaptureKit provides video sources for built-in and external cameras,
file-based playback, and test pattern generators. All sources conform
to the ``VideoSource`` protocol and produce `AsyncStream<VideoFrame>`
values.

## Source types

| Source | Type | Description |
|--------|------|-------------|
| ``CameraSource`` | `.builtInCamera` | Built-in device camera |
| ``ExternalCameraSource`` | `.externalCamera` | USB/Thunderbolt cameras |
| SpatialCameraSource | `.spatialCamera` | visionOS spatial camera |
| ``CinematicCameraSource`` | `.cinematicCamera` | Cinematic mode capture |
| ``MultiCameraSource`` | `.multiCamera` | Simultaneous multi-camera |
| ``FileVideoSource`` | `.file` | Video file playback |
| ``TestPatternSource`` | `.generator` | SMPTE/gradient test patterns |
| ``ColorSource`` | `.generator` | Solid color frames |
| ``BlackSource`` | `.generator` | Black frames |

## Configure a video source

Use ``VideoSourceConfiguration`` to set resolution, frame rate, pixel
format, color space, stabilization, focus, exposure, and white balance:

```swift
let source = CameraSource()
let config = VideoSourceConfiguration(
    resolution: .p1080,
    frameRate: .fps30,
    pixelFormat: .nv12,
    colorSpace: .bt709,
    dynamicRange: .sdr,
    stabilization: .cinematic,
    focusMode: .continuousAutoFocus,
    exposureMode: .continuousAutoExposure
)
try await source.configure(config)
```

## Camera controls

Camera sources provide additional controls:

```swift
// Switch between front and back camera
try await cameraEngine.switchCamera(to: .front)

// Adjust zoom
try await cameraEngine.setZoom(2.0)

// Toggle torch
try await cameraEngine.setTorch(.on)

// Set focus point
try await cameraEngine.setFocusPointOfInterest(x: 0.5, y: 0.5)
```

## Frame statistics

Every ``VideoSource`` exposes a ``VideoSource/frameStatistics`` stream
with real-time capture metrics:

```swift
for await stats in source.frameStatistics {
    print("FPS: \(stats.capturedFrameRate), dropped: \(stats.droppedFrames)")
}
```

## Test generators

``TestPatternSource``, ``ColorSource``, and ``BlackSource`` generate video
frames without camera hardware — ideal for testing encoding and output
pipelines.

## Next Steps

- <doc:ScreenCapture> — Capture screen content on macOS and iOS
- <doc:Encoding> — Encode video with H.264, HEVC, ProRes, AV1, or JPEG
- <doc:DeviceDiscovery> — Discover available cameras
