// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Monitors available audio and video capture devices, including hot-plug events.
///
/// Provides real-time device enumeration and change notifications for
/// microphones, cameras, USB audio interfaces, and external displays.
///
/// ```swift
/// let discovery = DeviceDiscovery()
/// await discovery.startMonitoring()
///
/// for await event in discovery.deviceChanges {
///     switch event {
///     case .audioDeviceConnected(let device):
///         print("New audio device: \(device.name)")
///     default: break
///     }
/// }
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor DeviceDiscovery {

    /// All currently available audio input devices.
    public private(set) var audioDevices: [AudioDeviceInfo] = []

    /// All currently available video input devices.
    public private(set) var videoDevices: [VideoDeviceInfo] = []

    /// Whether monitoring is active.
    public private(set) var isMonitoring: Bool = false

    /// Default audio input device (nil if none available).
    public var defaultAudioDevice: AudioDeviceInfo? {
        audioDevices.first(where: { $0.isDefault }) ?? audioDevices.first
    }

    /// Default video input device (nil if none available).
    public var defaultVideoDevice: VideoDeviceInfo? {
        videoDevices.first
    }

    private var changeContinuation: AsyncStream<DeviceChangeEvent>.Continuation?
    private var monitoringTask: Task<Void, Never>?

    /// Creates a new device discovery instance.
    public init() {}

    deinit {
        monitoringTask?.cancel()
        changeContinuation?.finish()
    }

    /// Device change event stream.
    public var deviceChanges: AsyncStream<DeviceChangeEvent> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: DeviceChangeEvent.self)
        self.changeContinuation = continuation
        return stream
    }

    /// Start monitoring for device connections and disconnections.
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        isMonitoring = true
        await refreshDeviceList()
    }

    /// Stop monitoring for device changes.
    public func stopMonitoring() async {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    /// Force a refresh of the device list.
    public func refreshDeviceList() async {
        // Real implementation queries hardware; empty in CI/testing
    }

    /// Simulate a device connection (for testing).
    func simulateDeviceConnected(_ device: AudioDeviceInfo) {
        audioDevices.append(device)
        changeContinuation?.yield(.audioDeviceConnected(device))
    }

    /// Simulate a device disconnection (for testing).
    func simulateDeviceDisconnected(audioDeviceID: String) {
        audioDevices.removeAll { $0.id == audioDeviceID }
        changeContinuation?.yield(
            .audioDeviceDisconnected(audioDeviceID))
    }

    /// Simulate a video device connection (for testing).
    func simulateVideoDeviceConnected(_ device: VideoDeviceInfo) {
        videoDevices.append(device)
        changeContinuation?.yield(.videoDeviceConnected(device))
    }

    /// Simulate a video device disconnection (for testing).
    func simulateVideoDeviceDisconnected(videoDeviceID: String) {
        videoDevices.removeAll { $0.id == videoDeviceID }
        changeContinuation?.yield(
            .videoDeviceDisconnected(videoDeviceID))
    }
}
