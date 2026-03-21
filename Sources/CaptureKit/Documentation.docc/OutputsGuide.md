# Outputs

Deliver encoded media to files, streams, callbacks, or audio preview.

## Overview

Outputs are the final stage of the capture pipeline. All outputs conform
to the ``CaptureOutput`` protocol and follow a prepare → receive → finalize
lifecycle. A ``CaptureSession`` can have multiple outputs simultaneously.

## Output types

| Output | Type | Description |
|--------|------|-------------|
| ``FileOutput`` | `.file` | Record to MP4, MOV, M4A, CAF, WAV, AIFF, or FLAC |
| ``CallbackOutput`` | `.callback` | Process encoded data with closures |
| ``AudioPreviewOutput`` | `.audioPreview` | Real-time audio playback monitoring |

## File recording

``FileOutput`` records encoded media to a file with automatic container
format handling:

```swift
let output = FileOutput(
    configuration: FileOutputConfiguration(
        url: recordingURL,
        container: .mp4,
        metadata: FileMetadata(title: "My Recording"),
        overwriteExisting: true
    )
)
try await session.addOutput(output)
```

### Supported containers

| Container | Extension | Audio | Video |
|-----------|-----------|-------|-------|
| `.mp4` | .mp4 | AAC, ALAC | H.264, HEVC, AV1 |
| `.mov` | .mov | AAC, ALAC, PCM | H.264, HEVC, ProRes |
| `.m4a` | .m4a | AAC, ALAC | No |
| `.caf` | .caf | AAC, ALAC, PCM, FLAC, Opus | No |
| `.wav` | .wav | PCM | No |
| `.aiff` | .aiff | PCM | No |
| `.flac` | .flac | FLAC | No |

### File rotation

Automatically split recordings by duration or file size:

```swift
let config = FileOutputConfiguration(
    url: baseURL,
    container: .mp4,
    rotation: .byDuration(3600, maxFiles: 24)
)
```

### Recording statistics

Monitor recording progress via ``FileOutput/recordingStatistics``:

```swift
let stats = await output.recordingStatistics
print("Duration: \(stats.duration)s, size: \(stats.fileSize) bytes")
```

## Callback output

``CallbackOutput`` delivers encoded buffers and frames to closures for
custom processing:

```swift
let callback = CallbackOutput(
    audioHandler: { buffer in
        // Process encoded audio
    },
    videoHandler: { frame in
        // Process encoded video
    }
)
try await session.addOutput(callback)
```

## Audio preview

``AudioPreviewOutput`` plays encoded audio through the system audio
output for real-time monitoring:

```swift
let preview = AudioPreviewOutput(volume: 0.8)
try await session.addOutput(preview)
```

## Multiple outputs

A single session supports multiple simultaneous outputs:

```swift
try await session.addOutput(fileOutput)
try await session.addOutput(callbackOutput)
try await session.addOutput(previewOutput)
```

## Output lifecycle

All outputs transition through ``CaptureOutputState`` values:
`idle` → `preparing` → `ready` → `active` → `finalized`.

## Next Steps

- <doc:StreamingGuide> — Live streaming with StreamingPipeline
- <doc:Encoding> — Encoder configuration options
- <doc:PresetsGuide> — Platform-specific presets for common workflows
