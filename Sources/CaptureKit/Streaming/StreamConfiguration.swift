// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Codec configuration data sent to the transport before the first media
/// packets.  Transports use this to initialise decoders on the receiving end
/// (e.g. AVCDecoderConfigurationRecord for RTMP, SPS/PPS for SRT MPEG-TS).
public enum StreamConfiguration: Sendable {

    /// Video codec configuration (e.g. H.264 SPS+PPS, HEVC VPS+SPS+PPS).
    case video(codec: VideoCodec, parameterSets: Data)

    /// Audio codec configuration (e.g. AAC AudioSpecificConfig).
    case audio(codec: AudioCodec, configData: Data)
}
