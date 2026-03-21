# Permissions

Request and manage microphone, camera, and screen recording permissions.

## Overview

CaptureKit provides ``PermissionManager`` for unified permission handling
across all Apple platforms, plus SwiftUI views for permission UI flows.

## Permission types

``PermissionType`` covers all permissions relevant to media capture:

| Permission | Description |
|------------|-------------|
| `.microphone` | Microphone access |
| `.camera` | Camera access |
| `.screenRecording` | Screen capture (macOS) |
| `.photoLibrary` | Photo library access |
| `.mediaLibrary` | Media library access |
| `.bluetooth` | Bluetooth device access |

## Check permission status

```swift
let manager = PermissionManager()
let status = await manager.status(for: .microphone)

switch status {
case .authorized:
    // Ready to capture
case .notDetermined:
    // Need to request
case .denied:
    // Direct user to Settings
case .restricted:
    // Device policy restriction
case .provisional:
    // Limited authorization
}
```

## Request permissions

Request a single permission:

```swift
let status = await manager.request(.microphone)
```

Request multiple permissions at once:

```swift
let results = await manager.requestAll(
    for: [.microphone, .camera]
)
```

## Automatic permission requests

``CaptureSessionConfiguration`` can automatically request permissions
when the session starts:

```swift
let config = CaptureSessionConfiguration(
    automaticallyRequestPermissions: true,
    reconnectOnDeviceDisconnect: true,
    maxReconnectAttempts: 3,
    statisticsUpdateInterval: 1.0,
    adaptivePolicy: .default
)
let session = CaptureSession(configuration: config)
```

## Monitor permission changes

```swift
for await change in manager.permissionChanges {
    print("\(change.type): \(change.oldStatus) → \(change.newStatus)")
}
```

## SwiftUI permission view

``CapturePermissionView`` provides a ready-made UI for requesting
capture permissions:

```swift
CapturePermissionView(permissions: [.microphone, .camera])
```

Use the ``SwiftUICore/View/capturePermissions(_:onResult:)`` modifier to
integrate permission requests into any view:

```swift
ContentView()
    .capturePermissions([.microphone, .camera]) { results in
        // Handle permission results
    }
```

## Next Steps

- <doc:GettingStarted> — Set up your first capture session
- <doc:AudioCapture> — Capture audio after granting microphone permission
- <doc:ScreenCapture> — Screen recording permission on macOS
