# Platform Compatibility

Understand platform-specific features and availability across Apple platforms.

## Overview

CaptureKit supports macOS 14+, iOS 17+, and visionOS 1.0+. Most features
are available on all platforms, but some capabilities are platform-specific.

## Platform availability

| Feature | macOS 14+ | iOS 17+ | visionOS 1.0+ |
|---------|-----------|---------|---------------|
| Microphone capture | Yes | Yes | Yes |
| Camera capture | Yes | Yes | Yes |
| Screen capture (ScreenCaptureKit) | Yes | No | No |
| Screen capture (ReplayKit) | No | Yes | No |
| System audio | Yes | No | No |
| Spatial camera | No | No | Yes |
| MV-HEVC encoding | Yes | No | Yes |
| MP3 encoding | Yes | No | No |
| Bluetooth audio | Yes | Yes | No |
| Continuity Camera | Yes | No | No |
| Multi-camera | No | Yes | No |
| Cinematic mode | No | Yes | No |

## Conditional compilation

CaptureKit uses conditional compilation for platform-specific features:

```swift
// ScreenCaptureKit is macOS-only
#if canImport(ScreenCaptureKit)
let source = ScreenCaptureSource()
#endif

// visionOS spatial capture
#if os(visionOS)
let source = SpatialCameraSource()
let encoder = MVHEVCEncoder(configuration: .spatialVideo)
#endif

// Audio capture frameworks
#if canImport(AVFAudio)
let source = MicrophoneSource()
#endif
```

## MP3 encoding

``MP3Encoder`` is only available on macOS due to Apple framework
limitations:

```swift
#if os(macOS)
let encoder = MP3Encoder(configuration: .webRadio)
#endif
```

The ``AudioEncoderPreset`` type marks macOS-only presets via the
`isMacOSOnly` property.

## Screen recording permissions

Screen recording permission behavior differs by platform:

- **macOS**: Requires explicit user approval in System Settings > Privacy
- **iOS**: Uses ReplayKit which presents a system UI

## Hardware encoder availability

Hardware-accelerated encoders (H.264, HEVC, ProRes, AV1) depend on the
device's hardware capabilities. Use ``CaptureError/hardwareEncoderBusy``
to handle cases where the hardware encoder is occupied.

## Next Steps

- <doc:GettingStarted> — Set up CaptureKit
- <doc:PermissionsGuide> — Platform-specific permission handling
