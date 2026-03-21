# Device Discovery

Discover and monitor available audio and video devices.

## Overview

``DeviceDiscovery`` monitors the system for audio and video device
connections and disconnections, providing real-time device lists and
change events.

## Start monitoring

```swift
let discovery = DeviceDiscovery()
await discovery.startMonitoring()
```

## List available devices

```swift
let audioDevices = await discovery.audioDevices
let videoDevices = await discovery.videoDevices

for device in audioDevices {
    print("\(device.name) (\(device.connectionType))")
    print("  Channels: \(device.inputChannelCount)")
    print("  Sample rates: \(device.supportedSampleRates)")
}
```

## Get default devices

```swift
if let defaultMic = await discovery.defaultAudioDevice {
    print("Default mic: \(defaultMic.name)")
}

if let defaultCam = await discovery.defaultVideoDevice {
    print("Default camera: \(defaultCam.name)")
}
```

## Monitor device changes

Subscribe to the ``DeviceDiscovery/deviceChanges`` stream for real-time
notifications:

```swift
for await event in discovery.deviceChanges {
    switch event {
    case .audioDeviceConnected(let device):
        print("Connected: \(device.name)")
    case .audioDeviceDisconnected(let id):
        print("Disconnected: \(id)")
    case .videoDeviceConnected(let device):
        print("Camera connected: \(device.name)")
    case .videoDeviceDisconnected(let id):
        print("Camera disconnected: \(id)")
    case .defaultAudioDeviceChanged(let device):
        print("Default mic changed: \(device?.name ?? "none")")
    case .defaultVideoDeviceChanged(let device):
        print("Default camera changed: \(device?.name ?? "none")")
    }
}
```

## Device info

``AudioDeviceInfo`` provides device metadata:
- `id`, `name`, `manufacturer`, `modelID`
- `connectionType` — ``DeviceConnectionType`` (builtIn, usb, thunderbolt, bluetooth, continuityCamera, wireless)
- `inputChannelCount`, `supportedSampleRates`, `isDefault`

``VideoDeviceInfo`` provides camera metadata:
- `id`, `name`, `manufacturer`, `modelID`
- `position` — ``CameraPosition`` (front, back, unspecified)
- `deviceType` — ``CameraDeviceType`` (wideAngle, ultraWideAngle, telephoto, etc.)
- `hasFlash`, `hasTorch`, `supportsCinematic`, `supportsDepthData`

## Stop monitoring

```swift
await discovery.stopMonitoring()
```

## Next Steps

- <doc:AudioCapture> — Use discovered devices as audio sources
- <doc:VideoCapture> — Use discovered cameras as video sources
