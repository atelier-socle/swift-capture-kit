// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// A complete description of a video stream's format, covering resolution,
/// frame rate, pixel encoding, color space, dynamic range, and bit depth.
public struct VideoFormat: Sendable, Equatable, Hashable {
    /// The spatial dimensions of each frame.
    public let resolution: VideoResolution

    /// The number of frames per second.
    public let frameRate: FrameRate

    /// The pixel encoding format.
    public let pixelFormat: PixelFormat

    /// The color space used for color representation.
    public let colorSpace: ColorSpace

    /// The dynamic range capability.
    public let dynamicRange: DynamicRange

    /// The number of bits per color component.
    public let bitDepth: BitDepth

    /// Creates a new video format descriptor.
    ///
    /// - Parameters:
    ///   - resolution: The video resolution.
    ///   - frameRate: The frame rate.
    ///   - pixelFormat: The pixel format. Defaults to `.nv12`.
    ///   - colorSpace: The color space. Defaults to `.bt709`.
    ///   - dynamicRange: The dynamic range. Defaults to `.sdr`.
    ///   - bitDepth: The bit depth. Defaults to `.bit8`.
    public init(
        resolution: VideoResolution,
        frameRate: FrameRate,
        pixelFormat: PixelFormat = .nv12,
        colorSpace: ColorSpace = .bt709,
        dynamicRange: DynamicRange = .sdr,
        bitDepth: BitDepth = .bit8
    ) {
        self.resolution = resolution
        self.frameRate = frameRate
        self.pixelFormat = pixelFormat
        self.colorSpace = colorSpace
        self.dynamicRange = dynamicRange
        self.bitDepth = bitDepth
    }
}
