# ``CaptureKit``

Unified media capture, encoding, and delivery for Apple platforms.

@Metadata {
    @DisplayName("CaptureKit")
    @Available(macOS, introduced: "14.0")
    @Available(iOS, introduced: "17.0")
    @Available(visionOS, introduced: "1.0")
}

## Overview

CaptureKit provides a complete pipeline for capturing audio and video from
all available Apple sources, encoding with every Apple-supported codec, and
delivering to protocol-based outputs — files, callbacks, live streams, or
audio preview.

```swift
let session = CaptureSession()
session.audioSource = MicrophoneSource()
session.audioEncoder = AACEncoder(configuration: .podcast)
try await session.addOutput(FileOutput(url: recordingURL, container: .m4a))
try await session.start()
```

### Capture from every source

Microphone, line-in, system audio, Bluetooth, file, camera (built-in,
external, cinematic, spatial), screen capture (ScreenCaptureKit, ReplayKit),
test patterns, and tone/silence generators.

### Encode with every Apple codec

**Audio:** AAC (LC/HE/xHE), ALAC, Opus, FLAC, WAV, PCM, MP3.
**Video:** H.264, HEVC, ProRes, AV1, MV-HEVC, JPEG.

### Deliver anywhere

Record to file (MP4, MOV, M4A, CAF, WAV, AIFF, FLAC), stream via the
transport-agnostic ``StreamingTransport`` protocol, process with callbacks,
or preview audio in real time.

### Built for Swift concurrency

Every stateful type is an `actor`. Events flow through `AsyncStream`.
All public types are `Sendable`. Zero Combine, zero callbacks — pure
structured concurrency from capture to delivery.

## Topics

### Essentials

- <doc:GettingStarted>
- ``CaptureSession``
- ``CaptureSessionConfiguration``
- ``CaptureError``

### Audio Capture

- <doc:AudioCapture>
- ``AudioSource``
- ``AudioSourceConfiguration``
- ``AudioBuffer``
- ``AudioFormat``

### Video Capture

- <doc:VideoCapture>
- ``VideoSource``
- ``VideoSourceConfiguration``
- ``VideoFrame``
- ``VideoFormat``

### Screen Capture

- <doc:ScreenCapture>
- ``ScreenCaptureSource``
- ``ScreenCaptureMode``

### Audio Encoding

- <doc:Encoding>
- ``AudioEncoderProtocol``
- ``AACEncoder``
- ``ALACEncoder``
- ``OpusEncoder``
- ``FLACEncoder``
- ``WAVEncoder``
- ``PCMEncoder``
- ``MP3Encoder``

### Video Encoding

- ``VideoEncoderProtocol``
- ``H264Encoder``
- ``HEVCEncoder``
- ``ProResEncoder``
- ``AV1Encoder``
- ``MVHEVCEncoder``
- ``JPEGEncoder``

### Outputs

- <doc:OutputsGuide>
- ``CaptureOutput``
- ``FileOutput``
- ``CallbackOutput``
- ``AudioPreviewOutput``

### File Recording

- ``FileOutputConfiguration``
- ``FileContainer``
- ``FileMetadata``
- ``FileRotationConfiguration``
- ``RecordingStatistics``

### Streaming

- <doc:StreamingGuide>
- <doc:StreamingIntegration>
- ``StreamingPipeline``
- ``StreamingTransport``
- ``MediaPacket``
- ``StreamConfiguration``
- ``StreamingStats``

### Presets

- <doc:PresetsGuide>
- ``CapturePreset``
- ``CapturePresetConfiguration``
- ``AudioEncoderPreset``

### Permissions

- <doc:PermissionsGuide>
- ``PermissionManager``
- ``PermissionType``
- ``PermissionStatus``
- ``CapturePermissionView``

### Device Discovery

- <doc:DeviceDiscovery>
- ``DeviceDiscovery``
- ``AudioDeviceInfo``
- ``VideoDeviceInfo``
- ``DeviceChangeEvent``

### Audio Metering

- <doc:Metering>
- ``AudioMeter``
- ``AudioMeterConfiguration``
- ``AudioLevelSample``
- ``WaveformData``

### Formats

- <doc:FormatsGuide>
- ``SampleRate``
- ``AudioBitDepth``
- ``ChannelLayout``
- ``VideoResolution``
- ``FrameRate``
- ``PixelFormat``
- ``ColorSpace``
- ``DynamicRange``
- ``BitDepth``

### Codecs

- ``AudioCodec``
- ``VideoCodec``

### Encoded Media

- ``EncodedAudioBuffer``
- ``EncodedVideoFrame``

### Session State and Events

- ``CaptureSessionState``
- ``CaptureSessionEvent``
- ``CaptureSessionStatistics``
- ``CaptureQualityLevel``

### Adaptive Quality

- ``AdaptiveQualityManager``
- ``AdaptiveCapturePolicy``
- ``QualityAdjustment``
- ``StreamingTransportQuality``
- ``QualityGrade``

### Error Handling

- <doc:ErrorHandling>

### Platform Compatibility

- <doc:PlatformCompatibility>

### Testing

- <doc:TestingGuide>
