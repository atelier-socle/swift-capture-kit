// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Represents common video resolutions including standard, square, vertical,
/// and spatial formats, as well as arbitrary custom dimensions.
public enum VideoResolution: Sendable, Equatable, Hashable {
    /// 320x240 — Quarter VGA.
    case qvga

    /// 640x480 — VGA.
    case vga

    /// 960x540 — 540p.
    case p540

    /// 1280x720 — 720p HD.
    case p720

    /// 1920x1080 — 1080p Full HD.
    case p1080

    /// 2560x1440 — 1440p Quad HD.
    case p1440

    /// 3840x2160 — UHD 4K.
    case uhd4K

    /// 4096x2160 — DCI 4K.
    case dci4K

    /// 7680x4320 — UHD 8K.
    case uhd8K

    /// 720x720 — Square 720.
    case square720

    /// 1080x1080 — Square 1080.
    case square1080

    /// 720x1280 — Vertical 720.
    case vertical720

    /// 1080x1920 — Vertical 1080.
    case vertical1080

    /// 1920x1080 — Spatial video.
    case spatialVideo

    /// Custom resolution with the given width and height in pixels.
    case custom(width: Int, height: Int)

    /// The horizontal pixel count.
    public var width: Int {
        switch self {
        case .qvga: return 320
        case .vga: return 640
        case .p540: return 960
        case .p720: return 1280
        case .p1080: return 1920
        case .p1440: return 2560
        case .uhd4K: return 3840
        case .dci4K: return 4096
        case .uhd8K: return 7680
        case .square720: return 720
        case .square1080: return 1080
        case .vertical720: return 720
        case .vertical1080: return 1080
        case .spatialVideo: return 1920
        case .custom(let width, _): return width
        }
    }

    /// The vertical pixel count.
    public var height: Int {
        switch self {
        case .qvga: return 240
        case .vga: return 480
        case .p540: return 540
        case .p720: return 720
        case .p1080: return 1080
        case .p1440: return 1440
        case .uhd4K: return 2160
        case .dci4K: return 2160
        case .uhd8K: return 4320
        case .square720: return 720
        case .square1080: return 1080
        case .vertical720: return 1280
        case .vertical1080: return 1920
        case .spatialVideo: return 1080
        case .custom(_, let height): return height
        }
    }

    /// The aspect ratio expressed as width divided by height.
    public var aspectRatio: Double {
        Double(width) / Double(height)
    }

    /// The total number of pixels (width multiplied by height).
    public var totalPixels: Int {
        width * height
    }
}
