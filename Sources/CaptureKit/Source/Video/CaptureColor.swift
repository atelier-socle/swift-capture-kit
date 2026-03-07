// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// A BGRA pixel with 8-bit unsigned integer components.
public struct BGRAPixel: Sendable, Equatable {
    /// Blue component.
    public let b: UInt8
    /// Green component.
    public let g: UInt8
    /// Red component.
    public let r: UInt8
    /// Alpha component.
    public let a: UInt8
}

/// A platform-independent color representation for video generators.
public struct CaptureColor: Sendable, Equatable, Hashable {
    /// Red component (0.0–1.0).
    public let red: Float

    /// Green component (0.0–1.0).
    public let green: Float

    /// Blue component (0.0–1.0).
    public let blue: Float

    /// Alpha component (0.0–1.0).
    public let alpha: Float

    /// Creates a new capture color.
    ///
    /// - Parameters:
    ///   - red: Red component (0.0–1.0).
    ///   - green: Green component (0.0–1.0).
    ///   - blue: Blue component (0.0–1.0).
    ///   - alpha: Alpha component (0.0–1.0). Defaults to `1.0`.
    public init(red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    /// Black color.
    public static let black = CaptureColor(red: 0, green: 0, blue: 0)

    /// White color.
    public static let white = CaptureColor(red: 1, green: 1, blue: 1)

    /// Red color.
    public static let red = CaptureColor(red: 1, green: 0, blue: 0)

    /// Green color.
    public static let green = CaptureColor(red: 0, green: 1, blue: 0)

    /// Blue color.
    public static let blue = CaptureColor(red: 0, green: 0, blue: 1)

    /// Gray color (50% brightness).
    public static let gray = CaptureColor(red: 0.5, green: 0.5, blue: 0.5)
}
