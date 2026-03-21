# Testing

Test CaptureKit integrations without hardware dependencies.

## Overview

CaptureKit is designed for testability. Protocol-based architecture,
dependency injection, and generator sources make it possible to test
the entire pipeline without microphones, cameras, or hardware encoders.

## Generator sources

Use generator sources instead of hardware devices in tests:

```swift
// Silent audio source
let audioSource = SilenceSource()

// Tone generator
let audioSource = ToneSource()

// Test pattern video source
let videoSource = TestPatternSource()

// Solid color video source
let videoSource = ColorSource()

// Black frames
let videoSource = BlackSource()
```

## Protocol-based mocking

All key types are protocol-based, making them easy to mock:

- ``AudioSource`` — mock audio input
- ``VideoSource`` — mock video input
- ``AudioEncoderProtocol`` — mock audio encoding
- ``VideoEncoderProtocol`` — mock video encoding
- ``CaptureOutput`` — mock output delivery
- ``StreamingTransport`` — mock streaming transport

## Test encoder lifecycle

Test encoders directly using the actor-based API:

```swift
@Test("AAC encoder lifecycle")
func aacEncoderLifecycle() async throws {
    let encoder = AACEncoder(configuration: .podcast)
    try await encoder.configure(aac: .podcast)

    let buffer = AudioBuffer(
        data: Data(repeating: 0, count: 1024),
        format: AudioFormat(
            sampleRate: .rate48000,
            channelCount: 2,
            bitDepth: .int16
        ),
        timestamp: 0.0,
        duration: 0.02,
        sequenceNumber: 1
    )

    let encoded = try await encoder.encode(buffer)
    #expect(encoded.codec == .aac)

    let flushed = try await encoder.flush()
    await encoder.reset()
    #expect(await encoder.isConfigured == false)
}
```

## Test with CallbackOutput

Use ``CallbackOutput`` to verify encoded data reaches the output:

```swift
@Test("audio reaches callback output")
func audioReachesCallback() async throws {
    var receivedCount = 0

    let output = CallbackOutput(
        audioHandler: { _ in
            receivedCount += 1
        }
    )

    try await output.prepare(audioFormat: nil, videoFormat: nil)

    let buffer = EncodedAudioBuffer(
        data: Data([0x01]),
        codec: .aac,
        timestamp: 0,
        duration: 0.1,
        sequenceNumber: 0
    )
    try await output.receiveAudio(buffer)
    #expect(receivedCount == 1)
}
```

## Test tags

CaptureKit tests use tags for CI exclusion:

- `.hardware` — requires physical audio/video devices
- `.network` — requires network access

```swift
@Test("hardware encoding", .tags(.hardware))
func hardwareEncoding() async throws {
    // Only runs when hardware is available
}
```

## Configuration validation

Test encoder configurations without hardware:

```swift
@Test("invalid H.264 config throws")
func invalidH264Config() throws {
    let config = H264EncoderConfiguration(
        profile: .baseline,
        entropyMode: .cabac
    )
    #expect(throws: CaptureError.self) {
        try config.validate()
    }
}
```

## Next Steps

- <doc:GettingStarted> — Set up CaptureKit in your project
- <doc:Encoding> — Encoder configuration and presets
