# Formats

Audio and video format types used throughout CaptureKit.

## Overview

CaptureKit defines comprehensive format types for describing audio and
video streams. These types are used by sources, encoders, and outputs
to negotiate compatible configurations.

## Audio formats

``AudioFormat`` describes a complete audio stream:

```swift
let format = AudioFormat(
    sampleRate: .rate48000,
    channelCount: 2,
    channelLayout: .stereo,
    bitDepth: .float32,
    isInterleaved: true
)
```

### Sample rates

``SampleRate`` covers all standard rates from 8 kHz to 384 kHz:

| Rate | Use Case |
|------|----------|
| `.rate8000` | Telephony |
| `.rate16000` | Voice, VoIP |
| `.rate44100` | CD quality |
| `.rate48000` | Broadcast, streaming |
| `.rate96000` | High-resolution audio |
| `.rate192000` | Studio mastering |

### Audio bit depths

``AudioBitDepth`` defines sample precision:

| Depth | Byte Size | Use Case |
|-------|-----------|----------|
| `.int16` | 2 | CD, podcasts |
| `.int24` | 3 | Broadcast, studio |
| `.int32` | 4 | Processing headroom |
| `.float32` | 4 | CoreAudio native |
| `.float64` | 8 | Scientific, mastering |

### Channel layouts

``ChannelLayout`` supports mono through Ambisonics:
`mono`, `stereo`, `surround51`, `surround71`, `surround714`,
`ambisonicFOA`, `ambisonicSOA`, `ambisonicTOA`, `binaural`.

## Video formats

``VideoFormat`` describes a complete video stream:

```swift
let format = VideoFormat(
    resolution: .p1080,
    frameRate: .fps30,
    pixelFormat: .nv12,
    colorSpace: .bt709,
    dynamicRange: .sdr,
    bitDepth: .bit8
)
```

### Resolutions

``VideoResolution`` includes standard, social media, and spatial formats:

| Resolution | Size | Use Case |
|------------|------|----------|
| `.p720` | 1280x720 | Streaming |
| `.p1080` | 1920x1080 | Full HD |
| `.uhd4K` | 3840x2160 | Ultra HD |
| `.square1080` | 1080x1080 | Instagram |
| `.vertical1080` | 1080x1920 | TikTok, Reels |
| `.spatialVideo` | 1920x1080 (stereo) | visionOS |

### Frame rates

``FrameRate`` covers cinematic through high-speed capture:
`.fps24`, `.fps25`, `.fps29_97`, `.fps30`, `.fps60`, `.fps120`, `.fps240`.

### Pixel formats

``PixelFormat`` defines pixel layout:
`.nv12`, `.bgra`, `.p010` (10-bit), `.p210`, `.argb`, `.yuvs`.

### Color spaces and dynamic range

``ColorSpace``: `.srgb`, `.displayP3`, `.bt709`, `.bt2020`, `.bt2100PQ`, `.bt2100HLG`.

``DynamicRange``: `.sdr`, `.hdr10`, `.hdr10Plus`, `.dolbyVision`, `.hlg`.

## Codecs

``AudioCodec``: `.aac`, `.alac`, `.opus`, `.flac`, `.pcm`, `.mp3`.

``VideoCodec``: `.h264`, `.hevc`, `.prores`, `.av1`, `.mvHevc`, `.jpeg`.

## Next Steps

- <doc:Encoding> — Configure encoders with format types
- <doc:AudioCapture> — Audio source configuration
- <doc:VideoCapture> — Video source configuration
