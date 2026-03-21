# Error Handling

Handle errors from capture sessions, sources, encoders, and outputs.

## Overview

``CaptureError`` provides a comprehensive, categorized error enum covering
every failure point in the capture pipeline. All errors include descriptive
context to aid debugging.

## Error categories

### Session errors

```swift
case sessionNotConfigured
case sessionAlreadyRunning
case sessionNotRunning
case invalidConfiguration(String)
```

### Source errors

```swift
case sourceNotAvailable(sourceType: String, reason: String)
case sourceAlreadyCapturing(sourceID: String)
case sourceConfigurationFailed(sourceID: String, reason: String)
case deviceNotFound(deviceID: String)
case deviceDisconnected(deviceID: String)
case formatNotSupported(format: String)
```

### Encoder errors

```swift
case encoderNotAvailable(codec: String, reason: String)
case encoderConfigurationFailed(codec: String, reason: String)
case encodingFailed(codec: String, reason: String)
case hardwareEncoderBusy
case codecNotSupportedOnPlatform(codec: String, platform: String)
```

### Output errors

```swift
case outputPrepareFailed(outputID: String, reason: String)
case outputWriteFailed(outputID: String, reason: String)
case fileOutputDirectoryNotWritable(path: String)
case fileOutputRotationFailed(reason: String)
```

### Permission errors

```swift
case permissionDenied(PermissionType)
case permissionNotDetermined(PermissionType)
```

### Device errors

```swift
case noAudioDeviceAvailable
case noVideoDeviceAvailable
case aggregateDeviceCreationFailed(reason: String)
case deviceInUseByAnotherProcess(deviceID: String)
```

### Format conversion errors

```swift
case sampleRateConversionFailed
case channelLayoutConversionFailed
case pixelFormatConversionFailed
case colorSpaceConversionFailed
```

## Handle errors in a session

Monitor errors through the ``CaptureSession/events`` stream:

```swift
for await event in session.events {
    switch event {
    case .encoderError(let codec, let error):
        print("Encoder \(codec) failed: \(error)")
    case .sourceError(let sourceID, let error):
        print("Source \(sourceID) failed: \(error)")
    case .outputError(let outputID, let error):
        print("Output \(outputID) failed: \(error)")
    case .permissionDenied(let type):
        print("Permission denied: \(type)")
    default:
        break
    }
}
```

## Handle errors from direct API calls

All async methods throw ``CaptureError``:

```swift
do {
    try await session.start()
} catch let error as CaptureError {
    switch error {
    case .permissionDenied(let type):
        // Request permission
    case .sessionNotConfigured:
        // Add source and encoder
    default:
        print(error.description)
    }
}
```

## Next Steps

- <doc:PermissionsGuide> — Request permissions before capture
- <doc:GettingStarted> — Set up a capture session
