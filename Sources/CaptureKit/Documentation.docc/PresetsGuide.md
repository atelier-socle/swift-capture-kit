# Presets

Use ready-made configurations for common capture and encoding scenarios.

## Overview

CaptureKit provides three levels of presets: platform presets for
streaming services, audio encoder presets for common workflows, and
per-encoder configuration presets for fine-grained control.

## Platform presets

``CapturePreset`` provides static factory methods that return a
fully-configured ``CapturePresetConfiguration``:

| Preset | Video | Audio | Notes |
|--------|-------|-------|-------|
| `.twitch()` | H.264 720p 30fps 4 Mbps | AAC 128 kbps | Customizable resolution/fps |
| `.youtube()` | H.264 1080p 60fps 8 Mbps | AAC 128 kbps | Customizable resolution/fps |
| `.facebook()` | H.264 720p 30fps 4 Mbps | AAC 128 kbps | Customizable resolution/fps |
| `.instagram()` | H.264 1080x1080 30fps | AAC 128 kbps | Square format |
| `.tiktok()` | H.264 1080x1920 30fps | AAC 128 kbps | Vertical format |
| `.podcastAudio()` | None | AAC 128 kbps | Customizable channels/bitrate |
| `.podcastAudioHQ()` | None | AAC 256 kbps | High quality |
| `.podcastVideo()` | H.264 720p 30fps | AAC 128 kbps | Video podcast |
| `.podcastLossless()` | None | FLAC lossless | Archival quality |

```swift
let config = CapturePreset.twitch(resolution: .p720, frameRate: .fps30)
let session = CaptureSession.configured(with: config)
```

## Audio encoder presets

``AudioEncoderPreset`` provides 16 named presets organized by category:

### Podcast
- `.podcastStandard` — AAC-LC 128 kbps stereo
- `.podcastHQ` — AAC-LC 256 kbps stereo
- `.podcastLossless` — FLAC lossless stereo

### Music
- `.musicAAC` — AAC-LC 256 kbps VBR stereo
- `.musicLossless` — ALAC lossless stereo 24-bit

### Voice
- `.voiceOpus` — Opus 32 kbps mono VoIP
- `.voiceLowLatency` — AAC-ELD 32 kbps mono
- `.voiceMinimalBandwidth` — HE-AAC v2 24 kbps stereo

### Streaming
- `.streamingStandard` — AAC-LC 128 kbps stereo
- `.streamingHQ` — AAC-LC 320 kbps stereo
- `.streamingOpus` — Opus 128 kbps stereo

### Web Radio
- `.webRadioMP3128` — MP3 128 kbps stereo (macOS only)
- `.webRadioMP3320` — MP3 320 kbps stereo (macOS only)
- `.webRadioAAC96` — AAC-LC 96 kbps stereo

### Broadcast
- `.broadcastPCM` — PCM 48 kHz 24-bit uncompressed
- `.broadcastFLAC` — FLAC 48 kHz 24-bit lossless

## Per-encoder presets

Each encoder configuration type provides static presets:

```swift
// Audio
AACEncoderConfiguration.podcast      // AAC-LC stereo 128 kbps
FLACEncoderConfiguration.balanced    // Level 5 compression
WAVEncoderConfiguration.cdQuality    // 44.1 kHz 16-bit stereo

// Video
H264EncoderConfiguration.streaming1080p  // High, 4.5 Mbps, CABAC
HEVCEncoderConfiguration.hdr4K          // Main10, 25 Mbps, HDR10
ProResEncoderConfiguration.hq           // ProRes HQ
```

## Next Steps

- <doc:Encoding> — Detailed encoder configuration options
- <doc:StreamingGuide> — Use presets with StreamingPipeline
