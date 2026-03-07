// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Defines how screen content is captured, routing to the appropriate
/// platform-specific implementation.
public enum ScreenCaptureMode: Sendable, Equatable {
    /// macOS: Full system screen capture via ScreenCaptureKit.
    /// Captures a specific display, window, app, or region.
    case screenCaptureKit(ScreenCaptureKitTarget)

    /// iOS/iPadOS: In-app screen recording via ReplayKit.
    /// Captures only the current app's content.
    case replayKit

    /// iOS/iPadOS: System-wide screen capture via Broadcast Upload Extension.
    /// Requires a separate extension target with shared App Group.
    case broadcastExtension(appGroupID: String)
}

/// Target for ScreenCaptureKit capture (macOS).
/// Uses platform-independent identifiers — resolved to SCDisplay/SCWindow
/// at runtime via ScreenCaptureKit.
public enum ScreenCaptureKitTarget: Sendable, Equatable {
    /// Capture an entire display.
    case display(displayID: UInt32)

    /// Capture a specific window.
    case window(windowID: UInt32)

    /// Capture a specific application.
    case application(bundleID: String)

    /// Capture a region of a display.
    case region(x: Double, y: Double, width: Double, height: Double, displayID: UInt32)
}
