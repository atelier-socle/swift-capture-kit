# Audio Capture

Capture audio from microphones, line-in, system audio, Bluetooth, files, and generators.

## Overview

CaptureKit provides audio sources for every input on Apple platforms. All
sources conform to the ``AudioSource`` protocol and produce `AsyncStream<AudioBuffer>`
values for downstream encoding and delivery.

## Source types

| Source | Type | Description |
|--------|------|-------------|
| ``MicrophoneSource`` | `.microphone` | Built-in or default microphone |
| ``LineInSource`` | `.lineIn` | Line-in audio input |
| ``SystemAudioSource`` | `.systemAudio` | macOS system audio via ScreenCaptureKit |
| ``BluetoothAudioSource`` | `.bluetooth` | Bluetooth audio devices |
| ``AggregateAudioSource`` | `.aggregate` | Multiple devices merged |
| ``FileAudioSource`` | `.file` | Audio file playback |
| ``VoIPAudioSource`` | `.voip` | VoIP-optimized capture |
| ``ToneSource`` | `.generator` | Sine/square wave generator |
| ``SilenceSource`` | `.generator` | Silent audio generator |

## Configure an audio source

Use ``AudioSourceConfiguration`` to set sample rate, channels, bit depth,
and buffer duration:

```swift
let source = MicrophoneSource()
let config = AudioSourceConfiguration(
    sampleRate: .rate48000,
    channelCount: 2,
    channelLayout: .stereo,
    bitDepth: .float32,
    preferredBufferDuration: 0.02
)
try await source.configure(config)
```

## Start capture

Sources produce an `AsyncStream<AudioBuffer>`:

```swift
let stream = try await source.startCapture()
for await buffer in stream {
    // Process raw audio buffer
}
```

In practice, you assign the source to a ``CaptureSession`` which manages
the capture lifecycle automatically.

## Monitor audio levels

Every ``AudioSource`` exposes an ``AudioSource/audioLevel`` stream of
``AudioLevelSample`` values with peak, RMS, and optional EBU R128
loudness measurements:

```swift
Task {
    for await level in source.audioLevel {
        print("Peak: \(level.peakLevel) dBFS, RMS: \(level.rmsLevel) dBFS")
    }
}
```

## File-based audio

``FileAudioSource`` reads audio from a file and delivers it as a stream
of ``AudioBuffer`` values, useful for testing or playback scenarios.

## Test generators

``ToneSource`` generates sine or square waves at a specified frequency.
``SilenceSource`` generates silent audio buffers. Both are useful for
testing pipelines without hardware.

## Next Steps

- <doc:Encoding> — Encode captured audio with AAC, ALAC, Opus, FLAC, or PCM
- <doc:Metering> — Real-time level and waveform metering
- <doc:DeviceDiscovery> — Discover and monitor available audio devices
