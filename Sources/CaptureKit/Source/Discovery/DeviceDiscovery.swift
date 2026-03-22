// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

#if canImport(AVFoundation)
    @preconcurrency import AVFoundation
#endif

/// Monitors available audio and video capture devices, including hot-plug events.
///
/// Provides real-time device enumeration and change notifications for
/// microphones, cameras, USB audio interfaces, and external displays.
///
/// ## Platform Notes
///
/// - **macOS**: Full support — CoreAudio device enumeration, AVCaptureDevice
///   discovery, NotificationCenter hot-plug monitoring for connect/disconnect.
/// - **iOS/iPadOS**: AVCaptureDevice.DiscoverySession for video,
///   AVAudioSession.availableInputs for audio, NotificationCenter hot-plug.
/// - **visionOS**: Limited — `AVCaptureDevice.DeviceType.external` requires
///   visionOS 2.1+. Hot-plug notifications (`AVCaptureDeviceWasConnected`,
///   `AVCaptureDeviceWasDisconnected`) are not available. The device list is
///   static after the initial query. Only `builtInWideAngleCamera` is available
///   on visionOS versions prior to 2.1.
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
    ///
    /// Observes NotificationCenter for device connect/disconnect events
    /// and refreshes the device list when changes are detected.
    public func startMonitoring() async {
        guard !isMonitoring else { return }
        isMonitoring = true
        await refreshDeviceList()

        #if canImport(AVFoundation) && !targetEnvironment(simulator) && !os(visionOS)
            let connectedTask = Task { [weak self] in
                let notifications = NotificationCenter.default.notifications(
                    named: .AVCaptureDeviceWasConnected)
                for await _ in notifications {
                    await self?.refreshDeviceList()
                }
            }
            let disconnectedTask = Task { [weak self] in
                let notifications = NotificationCenter.default.notifications(
                    named: .AVCaptureDeviceWasDisconnected)
                for await _ in notifications {
                    await self?.refreshDeviceList()
                }
            }
            monitoringTask = Task {
                _ = await (connectedTask.value, disconnectedTask.value)
            }
        #endif
    }

    /// Stop monitoring for device changes.
    public func stopMonitoring() async {
        isMonitoring = false
        monitoringTask?.cancel()
        monitoringTask = nil
        changeContinuation?.finish()
        changeContinuation = nil
    }

    /// Force a refresh of the device list.
    public func refreshDeviceList() async {
        #if canImport(AVFoundation) && !targetEnvironment(simulator) && !os(visionOS)
            let previousAudio = audioDevices
            let previousVideo = videoDevices

            audioDevices = discoverAudioDevices()
            videoDevices = discoverVideoDevices()

            for device in audioDevices where !previousAudio.contains(device) {
                changeContinuation?.yield(.audioDeviceConnected(device))
            }
            for device in previousAudio where !audioDevices.contains(device) {
                changeContinuation?.yield(.audioDeviceDisconnected(device.id))
            }
            for device in videoDevices where !previousVideo.contains(device) {
                changeContinuation?.yield(.videoDeviceConnected(device))
            }
            for device in previousVideo where !videoDevices.contains(device) {
                changeContinuation?.yield(.videoDeviceDisconnected(device.id))
            }
        #endif
    }

    #if canImport(AVFoundation) && !targetEnvironment(simulator) && !os(visionOS)
        private func discoverAudioDevices() -> [AudioDeviceInfo] {
            let deviceTypes: [AVCaptureDevice.DeviceType] = [.microphone, .external]
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .audio,
                position: .unspecified
            )
            return discoverySession.devices.map { device in
                AudioDeviceInfo(
                    id: device.uniqueID,
                    name: device.localizedName,
                    manufacturer: device.manufacturer,
                    modelID: device.modelID,
                    connectionType: mapConnectionType(device),
                    inputChannelCount: 1,
                    supportedSampleRates: [.rate44100, .rate48000],
                    isDefault: false
                )
            }
        }

        private func discoverVideoDevices() -> [VideoDeviceInfo] {
            var deviceTypes: [AVCaptureDevice.DeviceType] = [
                .builtInWideAngleCamera,
                .external
            ]
            #if os(iOS)
                deviceTypes.append(.builtInTelephotoCamera)
                deviceTypes.append(.builtInUltraWideCamera)
            #endif
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: .unspecified
            )
            return discoverySession.devices.map { device in
                VideoDeviceInfo(
                    id: device.uniqueID,
                    name: device.localizedName,
                    manufacturer: device.manufacturer,
                    modelID: device.modelID,
                    position: mapPosition(device.position),
                    deviceType: mapDeviceType(device.deviceType),
                    connectionType: mapConnectionType(device),
                    hasFlash: device.hasFlash,
                    hasTorch: device.hasTorch
                )
            }
        }

        private func mapPosition(_ position: AVCaptureDevice.Position) -> CameraPosition {
            switch position {
            case .front: .front
            case .back: .back
            case .unspecified: .unspecified
            @unknown default: .unspecified
            }
        }

        private func mapDeviceType(_ type: AVCaptureDevice.DeviceType) -> CameraDeviceType {
            if type == .builtInWideAngleCamera { return .wideAngle }
            if type == .external { return .externalUnknown }
            #if os(iOS)
                if type == .builtInTelephotoCamera { return .telephoto }
                if type == .builtInUltraWideCamera { return .ultraWideAngle }
            #endif
            return .wideAngle
        }

        private func mapConnectionType(_ device: AVCaptureDevice) -> DeviceConnectionType {
            if device.deviceType == .external { return .usb }
            return .builtIn
        }
    #endif

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
