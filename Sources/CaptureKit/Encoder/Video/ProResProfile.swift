// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Apple ProRes encoding profile.
public enum ProResProfile: String, Sendable, CaseIterable {
    /// ProRes 422 Proxy — lowest data rate (~45 Mbps at 1080p).
    case proxy
    /// ProRes 422 LT — low data rate (~102 Mbps at 1080p).
    case lt
    /// ProRes 422 — standard quality (~147 Mbps at 1080p).
    case standard
    /// ProRes 422 HQ — high quality (~220 Mbps at 1080p).
    case hq
    /// ProRes 4444 — with alpha channel support (~330 Mbps at 1080p).
    case p4444
    /// ProRes 4444 XQ — highest quality (~500 Mbps at 1080p).
    case p4444xq

    /// Approximate data rate at 1080p30 in Mbps.
    public var approximateBitrateMbps1080p: Int {
        switch self {
        case .proxy: return 45
        case .lt: return 102
        case .standard: return 147
        case .hq: return 220
        case .p4444: return 330
        case .p4444xq: return 500
        }
    }

    /// Whether this profile supports alpha channel.
    public var supportsAlpha: Bool {
        switch self {
        case .p4444, .p4444xq: return true
        default: return false
        }
    }

    /// Whether this profile uses 4:2:2 chroma subsampling.
    public var is422: Bool {
        switch self {
        case .proxy, .lt, .standard, .hq: return true
        case .p4444, .p4444xq: return false
        }
    }
}
