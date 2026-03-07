// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Describes the pixel encoding format used for video sample buffers.
public enum PixelFormat: String, Sendable, CaseIterable {
    /// 420v — YCbCr 4:2:0 biplanar (default, most efficient).
    case nv12

    /// BGRA 8-bit — suitable for CoreImage and Metal pipelines.
    case bgra

    /// 4:2:2 10-bit — professional video.
    case p210

    /// 4:2:0 10-bit — HDR video.
    case p010

    /// ARGB 8-bit.
    case argb

    /// 422 YpCbCr8 — legacy format.
    case yuvs
}
