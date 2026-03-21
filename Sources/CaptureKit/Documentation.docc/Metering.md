# Audio Metering

Monitor audio levels, loudness, and waveforms in real time.

## Overview

``AudioMeter`` processes audio buffers and produces real-time level
measurements, EBU R128 loudness values, and waveform data for visual
rendering.

## Create and start a meter

```swift
let meter = AudioMeter(configuration: .broadcast)
await meter.start()
```

## Monitor levels

Subscribe to the ``AudioMeter/levels`` stream for ``AudioLevelSample``
values:

```swift
for await level in meter.levels {
    print("Peak: \(level.peakLevel) dBFS")
    print("RMS: \(level.rmsLevel) dBFS")

    for channel in level.channels {
        print("  Ch\(channel.channel): peak \(channel.peak), rms \(channel.rms)")
    }
}
```

## Loudness measurements

When using `.loudness` or `.full` metering mode, ``AudioLevelSample``
includes EBU R128 values:

```swift
let meter = AudioMeter(configuration: .loudnessCompliance)
await meter.start()

for await level in meter.levels {
    if let momentary = level.momentaryLoudness {
        print("Momentary: \(momentary) LUFS")
    }
    if let shortTerm = level.shortTermLoudness {
        print("Short-term: \(shortTerm) LUFS")
    }
    if let integrated = level.integratedLoudness {
        print("Integrated: \(integrated) LUFS")
    }
}
```

## Waveform data

Enable waveform generation for visual rendering:

```swift
let meter = AudioMeter(configuration: .podcast)
await meter.start()

for await waveform in meter.waveforms {
    // Simple bars (normalized 0.0-1.0)
    for bar in waveform.bars {
        // Draw amplitude bar
    }

    // Detailed min/max buckets for DAW-style display
    for bucket in waveform.minMax {
        // Draw min/max range
    }
}
```

## Configuration presets

``AudioMeterConfiguration`` provides presets for common use cases:

| Preset | Mode | Waveform | Update Rate |
|--------|------|----------|-------------|
| `.broadcast` | Full | Disabled | 60 Hz |
| `.podcast` | Peak+RMS | 100 bars | 30 Hz |
| `.loudnessCompliance` | Loudness | Disabled | 10 Hz |
| `.voiceMessage` | Peak+RMS | 50 bars | 30 Hz |
| `.dawEditing` | Full | Detailed (256 spp) | 60 Hz |

## Waveform modes

``WaveformMode`` controls waveform data generation:

| Mode | Output |
|------|--------|
| `.simple(barCount:)` | Normalized amplitude bars |
| `.detailed(samplesPerBucket:)` | Min/max/RMS per bucket |
| `.both(barCount:samplesPerBucket:)` | Both simple and detailed |
| `.disabled` | No waveform (saves CPU) |

## Feed buffers to the meter

In a custom pipeline, call ``AudioMeter/processBuffer(_:)`` directly:

```swift
await meter.processBuffer(audioBuffer)
```

When using ``CaptureSession``, level data flows automatically through the
``AudioSource/audioLevel`` stream.

## Next Steps

- <doc:AudioCapture> — Audio source configuration
- <doc:FormatsGuide> — Audio format types
