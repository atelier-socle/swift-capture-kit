// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Photo file format.
public enum PhotoFormat: String, Sendable, CaseIterable {
    /// High Efficiency Image File Format.
    case heif

    /// JPEG format.
    case jpeg

    /// RAW format.
    case raw

    /// Apple ProRAW format.
    case proRaw
}

/// Settings for capturing a still photo during video recording.
public struct PhotoCaptureSettings: Sendable {
    /// Whether to use flash.
    public var flashMode: TorchMode

    /// Whether to capture in HDR.
    public var hdrEnabled: Bool

    /// HEIF or JPEG.
    public var format: PhotoFormat

    /// Creates new photo capture settings.
    ///
    /// - Parameters:
    ///   - flashMode: The flash mode. Defaults to `.auto`.
    ///   - hdrEnabled: Whether HDR is enabled. Defaults to `false`.
    ///   - format: The photo format. Defaults to `.heif`.
    public init(
        flashMode: TorchMode = .auto,
        hdrEnabled: Bool = false,
        format: PhotoFormat = .heif
    ) {
        self.flashMode = flashMode
        self.hdrEnabled = hdrEnabled
        self.format = format
    }
}

/// A captured still photo.
public struct CapturedPhoto: Sendable {
    /// The photo data.
    public let data: Data

    /// Photo format.
    public let format: PhotoFormat

    /// Capture timestamp.
    public let timestamp: TimeInterval

    /// Image width in pixels.
    public let width: Int

    /// Image height in pixels.
    public let height: Int

    /// Creates a new captured photo.
    ///
    /// - Parameters:
    ///   - data: The photo data.
    ///   - format: The photo format.
    ///   - timestamp: The capture timestamp.
    ///   - width: The image width in pixels.
    ///   - height: The image height in pixels.
    public init(data: Data, format: PhotoFormat, timestamp: TimeInterval, width: Int, height: Int) {
        self.data = data
        self.format = format
        self.timestamp = timestamp
        self.width = width
        self.height = height
    }
}
