// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Identifies the type of system permission required for a capture operation.
public enum PermissionType: String, Sendable, CaseIterable {
    /// Permission to access the device microphone.
    case microphone

    /// Permission to access the device camera.
    case camera

    /// Permission to record the screen contents.
    case screenRecording

    /// Permission to access the photo library.
    case photoLibrary

    /// Permission to access the media library.
    case mediaLibrary

    /// Permission to access Bluetooth devices.
    case bluetooth
}

/// Represents a discrete quality level for capture output, ordered from
/// highest to lowest.
///
/// Conforms to ``Comparable`` so that ``maximum`` is greater than all other
/// levels and ``minimum`` is less than all other levels.
public enum CaptureQualityLevel: String, Sendable, CaseIterable, Comparable {
    /// The highest possible capture quality.
    case maximum

    /// High capture quality.
    case high

    /// Medium capture quality.
    case medium

    /// Low capture quality.
    case low

    /// The lowest possible capture quality.
    case minimum

    /// The ordinal value used for comparison, where a higher value represents
    /// higher quality.
    private var ordinal: Int {
        switch self {
        case .maximum: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        case .minimum: return 0
        }
    }

    /// Compares two quality levels by their ordinal rank.
    public static func < (lhs: CaptureQualityLevel, rhs: CaptureQualityLevel) -> Bool {
        lhs.ordinal < rhs.ordinal
    }
}

/// An event emitted by a capture session to communicate state changes,
/// errors, and diagnostic information.
public enum CaptureSessionEvent: Sendable {
    /// The session transitioned to a new state.
    case stateChanged(CaptureSessionState)

    /// An audio source is ready to deliver buffers.
    case audioSourceReady(sourceID: String)

    /// A video source is ready to deliver frames.
    case videoSourceReady(sourceID: String)

    /// An output was added to the session.
    case outputAdded(String)

    /// An output was removed from the session.
    case outputRemoved(String)

    /// An output encountered an error.
    case outputError(outputID: String, error: any Error)

    /// An encoder encountered an error.
    case encoderError(codec: String, error: any Error)

    /// A source encountered an error.
    case sourceError(sourceID: String, error: any Error)

    /// A required permission was denied by the user or system.
    case permissionDenied(PermissionType)

    /// A device was disconnected from the system.
    case deviceDisconnected(deviceID: String)

    /// A device was connected to the system.
    case deviceConnected(deviceID: String)

    /// The audio or video bitrate changed.
    case bitrateChanged(audio: Int?, video: Int?)

    /// Frames were dropped during capture.
    case droppedFrames(count: Int, reason: String)

    /// Updated capture session statistics are available.
    case statisticsUpdated(CaptureSessionStatistics)

    /// The transport quality of a streaming output changed.
    case transportQualityChanged(output: String, quality: StreamingTransportQuality)

    /// The capture quality was reduced due to resource constraints.
    case captureQualityReduced(reason: String, from: CaptureQualityLevel, to: CaptureQualityLevel)

    /// The capture quality was restored after conditions improved.
    case captureQualityRestored(reason: String, to: CaptureQualityLevel)
}
