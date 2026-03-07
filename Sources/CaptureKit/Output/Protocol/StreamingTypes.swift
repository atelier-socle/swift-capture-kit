// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Represents the connection state of a streaming transport.
public enum StreamingConnectionState: String, Sendable, CaseIterable {
    /// The transport is not connected.
    case disconnected

    /// The transport is in the process of connecting.
    case connecting

    /// The transport is connected and ready for data.
    case connected

    /// The transport is attempting to reconnect after a disruption.
    case reconnecting

    /// The transport connection has failed.
    case failed
}

/// Describes the quality of a streaming transport connection with a numeric score and grade.
public struct StreamingTransportQuality: Sendable, Equatable {
    /// A numeric quality score from 0.0 (worst) to 1.0 (best).
    public let score: Double

    /// The quality grade derived from the score.
    public let grade: QualityGrade

    /// The recommended bitrate in bits per second based on transport conditions, if available.
    public let recommendedBitrate: Int?

    /// Creates a new streaming transport quality descriptor.
    ///
    /// - Parameters:
    ///   - score: A numeric quality score from 0.0 to 1.0.
    ///   - grade: The quality grade.
    ///   - recommendedBitrate: The recommended bitrate in bits per second. Defaults to `nil`.
    public init(score: Double, grade: QualityGrade, recommendedBitrate: Int? = nil) {
        self.score = score
        self.grade = grade
        self.recommendedBitrate = recommendedBitrate
    }
}

/// Represents a quality grade used to evaluate and constrain capture quality
/// in adaptive policies.
public enum QualityGrade: String, Sendable, CaseIterable, Comparable {
    /// The highest quality grade — no compromises.
    case excellent

    /// Good quality — minor imperfections acceptable.
    case good

    /// Fair quality — noticeable degradation but usable.
    case fair

    /// Poor quality — significant degradation.
    case poor

    /// Critical quality — near failure, intervention required.
    case critical

    /// The ordinal value used for comparison, where higher means better quality.
    private var ordinal: Int {
        switch self {
        case .excellent: return 4
        case .good: return 3
        case .fair: return 2
        case .poor: return 1
        case .critical: return 0
        }
    }

    /// Compares two quality grades by their ordinal rank.
    public static func < (lhs: QualityGrade, rhs: QualityGrade) -> Bool {
        lhs.ordinal < rhs.ordinal
    }
}
