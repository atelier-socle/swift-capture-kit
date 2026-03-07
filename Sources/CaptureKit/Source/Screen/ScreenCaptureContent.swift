// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Platform-independent rectangle (avoids CGRect dependency in public API).
public struct ScreenRect: Sendable, Equatable, Hashable {
    /// The x coordinate.
    public let x: Double

    /// The y coordinate.
    public let y: Double

    /// The width.
    public let width: Double

    /// The height.
    public let height: Double

    /// Creates a new screen rect.
    ///
    /// - Parameters:
    ///   - x: The x coordinate.
    ///   - y: The y coordinate.
    ///   - width: The width.
    ///   - height: The height.
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// A display available for screen capture.
public struct ScreenDisplay: Sendable, Identifiable, Equatable, Hashable {
    /// Display identifier.
    public let id: UInt32

    /// Display width in pixels.
    public let width: Int

    /// Display height in pixels.
    public let height: Int

    /// Display frame (position and size on desktop).
    public let frame: ScreenRect

    /// Whether this is the main display.
    public let isMain: Bool

    /// Creates a new screen display descriptor.
    ///
    /// - Parameters:
    ///   - id: The display identifier.
    ///   - width: The display width in pixels.
    ///   - height: The display height in pixels.
    ///   - frame: The display frame.
    ///   - isMain: Whether this is the main display.
    public init(id: UInt32, width: Int, height: Int, frame: ScreenRect, isMain: Bool) {
        self.id = id
        self.width = width
        self.height = height
        self.frame = frame
        self.isMain = isMain
    }
}

/// A window available for screen capture.
public struct ScreenWindow: Sendable, Identifiable, Equatable, Hashable {
    /// Window identifier.
    public let id: UInt32

    /// Window title.
    public let title: String?

    /// Owning application's bundle identifier.
    public let owningApplicationBundleID: String?

    /// Owning application's name.
    public let owningApplicationName: String?

    /// Window frame.
    public let frame: ScreenRect

    /// Whether the window is on screen.
    public let isOnScreen: Bool

    /// Window layer (lower = closer to user).
    public let windowLayer: Int

    /// Creates a new screen window descriptor.
    ///
    /// - Parameters:
    ///   - id: The window identifier.
    ///   - title: The window title.
    ///   - owningApplicationBundleID: The owning app's bundle ID.
    ///   - owningApplicationName: The owning app's name.
    ///   - frame: The window frame.
    ///   - isOnScreen: Whether the window is on screen.
    ///   - windowLayer: The window layer.
    public init(
        id: UInt32,
        title: String?,
        owningApplicationBundleID: String?,
        owningApplicationName: String?,
        frame: ScreenRect,
        isOnScreen: Bool,
        windowLayer: Int
    ) {
        self.id = id
        self.title = title
        self.owningApplicationBundleID = owningApplicationBundleID
        self.owningApplicationName = owningApplicationName
        self.frame = frame
        self.isOnScreen = isOnScreen
        self.windowLayer = windowLayer
    }
}

/// A running application available for screen capture.
public struct ScreenApplication: Sendable, Identifiable, Equatable, Hashable {
    /// Bundle identifier.
    public let id: String

    /// Application name.
    public let applicationName: String

    /// Creates a new screen application descriptor.
    ///
    /// - Parameters:
    ///   - id: The bundle identifier.
    ///   - applicationName: The application name.
    public init(id: String, applicationName: String) {
        self.id = id
        self.applicationName = applicationName
    }
}

/// Available screen capture content, discovered at runtime.
/// Platform-independent representation of available displays, windows, and apps.
public struct ScreenCaptureContent: Sendable {
    /// Available displays.
    public let displays: [ScreenDisplay]

    /// Available windows.
    public let windows: [ScreenWindow]

    /// Running applications.
    public let applications: [ScreenApplication]

    /// Creates a new screen capture content descriptor.
    ///
    /// - Parameters:
    ///   - displays: Available displays.
    ///   - windows: Available windows.
    ///   - applications: Running applications.
    public init(
        displays: [ScreenDisplay],
        windows: [ScreenWindow],
        applications: [ScreenApplication]
    ) {
        self.displays = displays
        self.windows = windows
        self.applications = applications
    }
}
