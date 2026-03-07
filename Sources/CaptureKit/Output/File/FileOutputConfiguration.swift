// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Configuration for file recording output.
public struct FileOutputConfiguration: Sendable, Equatable {
    /// Output file URL.
    public var url: URL

    /// Container format.
    public var container: FileContainer

    /// Optional metadata to embed in the file.
    public var metadata: FileMetadata?

    /// Whether to overwrite existing files.
    public var overwriteExisting: Bool

    /// File rotation configuration (nil = no rotation).
    public var rotation: FileRotationConfiguration?

    /// Creates a new file output configuration.
    ///
    /// - Parameters:
    ///   - url: The output file URL.
    ///   - container: The container format.
    ///   - metadata: Optional metadata to embed.
    ///   - overwriteExisting: Whether to overwrite existing files.
    ///   - rotation: Optional file rotation configuration.
    public init(
        url: URL,
        container: FileContainer,
        metadata: FileMetadata? = nil,
        overwriteExisting: Bool = false,
        rotation: FileRotationConfiguration? = nil
    ) {
        self.url = url
        self.container = container
        self.metadata = metadata
        self.overwriteExisting = overwriteExisting
        self.rotation = rotation
    }
}

/// Supported file container formats.
public enum FileContainer: String, Sendable, CaseIterable {
    /// MPEG-4 container (.mp4) — H.264, HEVC, AAC.
    case mp4
    /// QuickTime container (.mov) — all Apple codecs, ProRes.
    case mov
    /// MPEG-4 Audio (.m4a) — AAC, ALAC, audio-only.
    case m4a
    /// Core Audio Format (.caf) — any Apple audio codec.
    case caf
    /// Waveform Audio (.wav) — Linear PCM.
    case wav
    /// Audio Interchange (.aiff) — Linear PCM, Apple legacy.
    case aiff
    /// FLAC container (.flac) — FLAC lossless.
    case flac

    /// The file extension for this container format.
    public var fileExtension: String { rawValue }

    /// Whether this container supports video tracks.
    public var supportsVideo: Bool {
        switch self {
        case .mp4, .mov: true
        case .m4a, .caf, .wav, .aiff, .flac: false
        }
    }

    /// Whether this container supports audio tracks.
    public var supportsAudio: Bool { true }

    /// The audio codecs supported by this container.
    public var supportedAudioCodecs: [AudioCodec] {
        switch self {
        case .mp4: [.aac, .alac, .flac]
        case .mov: [.aac, .alac, .pcm, .flac]
        case .m4a: [.aac, .alac]
        case .caf: [.aac, .alac, .pcm, .flac, .opus, .mp3]
        case .wav: [.pcm]
        case .aiff: [.pcm]
        case .flac: [.flac]
        }
    }

    /// The video codecs supported by this container.
    public var supportedVideoCodecs: [VideoCodec] {
        switch self {
        case .mp4: [.h264, .hevc, .av1]
        case .mov: [.h264, .hevc, .prores, .av1, .mvHevc, .jpeg]
        case .m4a, .caf, .wav, .aiff, .flac: []
        }
    }
}

/// File metadata to embed in the output.
public struct FileMetadata: Sendable, Equatable {
    /// Title.
    public var title: String?
    /// Artist/author.
    public var artist: String?
    /// Album.
    public var album: String?
    /// Comment/description.
    public var comment: String?
    /// Creation date (nil = current date).
    public var creationDate: Date?
    /// Custom key-value metadata.
    public var custom: [String: String]

    /// Creates file metadata.
    ///
    /// - Parameters:
    ///   - title: The title.
    ///   - artist: The artist or author.
    ///   - album: The album name.
    ///   - comment: A comment or description.
    ///   - creationDate: The creation date.
    ///   - custom: Custom key-value metadata pairs.
    public init(
        title: String? = nil,
        artist: String? = nil,
        album: String? = nil,
        comment: String? = nil,
        creationDate: Date? = nil,
        custom: [String: String] = [:]
    ) {
        self.title = title
        self.artist = artist
        self.album = album
        self.comment = comment
        self.creationDate = creationDate
        self.custom = custom
    }
}
