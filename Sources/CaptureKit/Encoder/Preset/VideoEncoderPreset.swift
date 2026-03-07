// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Named presets for video encoding, combining codec + configuration.
public enum VideoEncoderPreset: String, Sendable, CaseIterable {
    // MARK: - Streaming

    /// H.264 High 720p 2.5 Mbps — Twitch/Facebook standard.
    case streaming720pH264
    /// H.264 High 1080p 4.5 Mbps — YouTube/Twitch standard.
    case streaming1080pH264
    /// H.264 High 1080p60 6 Mbps — YouTube HFR.
    case streaming1080p60H264
    /// HEVC 1080p 5 Mbps — efficient streaming.
    case streaming1080pHEVC
    /// HEVC 4K 20 Mbps — YouTube 4K.
    case streaming4KHEVC
    /// AV1 1080p 4 Mbps — next-gen streaming (M3+ required).
    case streaming1080pAV1

    // MARK: - Professional

    /// ProRes 422 Proxy — lightweight editing proxy.
    case proresProxy
    /// ProRes 422 HQ — high quality production.
    case proresHQ
    /// ProRes 4444 — VFX/compositing with alpha.
    case prores4444

    // MARK: - HDR

    /// HEVC Main10 HDR10 4K — standard HDR content.
    case hdr10_4K
    /// HEVC Main10 HLG — broadcast HDR.
    case hlgBroadcast
    /// HEVC Main10 Dolby Vision — premium HDR.
    case dolbyVision

    // MARK: - Spatial

    /// MV-HEVC spatial video — Apple Vision Pro.
    case spatialVideo
    /// MV-HEVC spatial video HQ — archival quality.
    case spatialVideoHQ

    // MARK: - Screen Recording

    /// H.264 High screen recording — 8 Mbps, optimized for UI content.
    case screenRecordingH264
    /// HEVC screen recording — 8 Mbps, more efficient.
    case screenRecordingHEVC

    // MARK: - Low Latency

    /// H.264 Baseline — no B-frames, CAVLC, minimal latency.
    case lowLatencyH264
    /// Motion JPEG — frame-independent, zero-latency.
    case lowLatencyJPEG

    /// The video codec used by this preset.
    public var codec: VideoCodec {
        switch self {
        case .streaming720pH264, .streaming1080pH264,
            .streaming1080p60H264, .screenRecordingH264,
            .lowLatencyH264:
            return .h264
        case .streaming1080pHEVC, .streaming4KHEVC,
            .screenRecordingHEVC, .hdr10_4K,
            .hlgBroadcast, .dolbyVision:
            return .hevc
        case .proresProxy, .proresHQ, .prores4444:
            return .prores
        case .streaming1080pAV1:
            return .av1
        case .spatialVideo, .spatialVideoHQ:
            return .mvHevc
        case .lowLatencyJPEG:
            return .jpeg
        }
    }

    /// Whether this preset requires specific hardware (M1+, M3+).
    public var minimumHardware: String? {
        switch self {
        case .streaming1080pAV1:
            return "Apple M3"
        case .proresProxy, .proresHQ, .prores4444,
            .spatialVideo, .spatialVideoHQ:
            return "Apple M1"
        default:
            return nil
        }
    }
}
