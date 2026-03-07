// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Events emitted when capture devices are connected, disconnected, or change.
public enum DeviceChangeEvent: Sendable {
    /// An audio input device was connected.
    case audioDeviceConnected(AudioDeviceInfo)
    /// An audio input device was disconnected (identified by device ID).
    case audioDeviceDisconnected(String)
    /// A video input device was connected.
    case videoDeviceConnected(VideoDeviceInfo)
    /// A video input device was disconnected (identified by device ID).
    case videoDeviceDisconnected(String)
    /// The default audio input device changed.
    case defaultAudioDeviceChanged(AudioDeviceInfo?)
    /// The default video input device changed.
    case defaultVideoDeviceChanged(VideoDeviceInfo?)
}
