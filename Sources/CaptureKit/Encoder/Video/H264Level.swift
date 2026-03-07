// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// H.264/AVC encoding level (determines max resolution, bitrate, and macroblocks).
public enum H264Level: String, Sendable, CaseIterable {
    /// 720x480 at 30fps.
    case level3
    /// 1280x720 at 30fps.
    case level31
    /// 1280x1024 at 42fps.
    case level32
    /// 2048x1024 at 30fps.
    case level4
    /// 2048x1024 at 30fps (higher bitrate).
    case level41
    /// 2048x1088 at 60fps.
    case level42
    /// 3672x1536 at 26fps.
    case level5
    /// 4096x2160 at 30fps.
    case level51
    /// 4096x2160 at 60fps.
    case level52
    /// Automatic level selection based on resolution and frame rate.
    case auto
}
