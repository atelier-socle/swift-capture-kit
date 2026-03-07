// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Manages automatic quality adjustment based on transport feedback.
///
/// When streaming outputs report quality degradation, this manager
/// determines the appropriate capture quality level and notifies
/// the CaptureSession to adjust encoding parameters.
///
/// The adjustment follows a graduated scale:
/// 1. Reduce video bitrate (first line of defense)
/// 2. Reduce video frame rate (if bitrate reduction insufficient)
/// 3. Reduce video resolution (last resort)
/// 4. Reduce audio bitrate (only in extreme cases)
///
/// Recovery follows the reverse path when quality improves.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor AdaptiveQualityManager {

    /// Current quality level.
    public private(set) var currentLevel: CaptureQualityLevel = .maximum

    /// The active policy.
    public let policy: AdaptiveCapturePolicy

    /// Number of consecutive degradation signals received.
    public private(set) var consecutiveDegradationCount: Int = 0

    /// Number of consecutive improvement signals received.
    public private(set) var consecutiveImprovementCount: Int = 0

    /// History of quality changes.
    public private(set) var qualityHistory: [QualityChange] = []

    /// Whether the manager is actively monitoring.
    public private(set) var isActive: Bool = false

    /// Creates a new adaptive quality manager.
    ///
    /// - Parameter policy: The adaptive capture policy to use.
    public init(policy: AdaptiveCapturePolicy = .default) {
        self.policy = policy
    }

    /// Start monitoring transport quality.
    public func start() {
        guard policy.enabled else { return }
        isActive = true
        currentLevel = .maximum
        consecutiveDegradationCount = 0
        consecutiveImprovementCount = 0
    }

    /// Stop monitoring.
    public func stop() {
        isActive = false
    }

    /// Process a transport quality report and determine if quality adjustment is needed.
    ///
    /// - Parameter quality: The transport quality report.
    /// - Returns: The quality adjustment action to take, if any.
    public func processQualityReport(
        _ quality: StreamingTransportQuality
    ) -> QualityAdjustment? {
        guard isActive, policy.enabled else { return nil }

        if quality.grade < policy.minimumGrade {
            consecutiveDegradationCount += 1
            consecutiveImprovementCount = 0

            let threshold = degradationThreshold(
                for: policy.responsiveness)
            if consecutiveDegradationCount >= threshold {
                return reduceQuality(
                    reason: "Transport quality \(quality.grade.rawValue)"
                )
            }
        } else if quality.grade >= .good {
            consecutiveImprovementCount += 1
            consecutiveDegradationCount = 0

            if consecutiveImprovementCount >= 3
                && currentLevel != .maximum
            {
                return restoreQuality(
                    reason: "Transport quality recovered")
            }
        } else {
            consecutiveDegradationCount = 0
            consecutiveImprovementCount = 0
        }

        return nil
    }

    /// Reset to maximum quality.
    public func reset() {
        currentLevel = .maximum
        consecutiveDegradationCount = 0
        consecutiveImprovementCount = 0
    }

    // MARK: - Private

    private func degradationThreshold(
        for responsiveness: AdaptiveCapturePolicy.Responsiveness
    ) -> Int {
        switch responsiveness {
        case .immediate: return 1
        case .responsive: return 2
        case .conservative: return 3
        }
    }

    private func reduceQuality(
        reason: String
    ) -> QualityAdjustment? {
        let previousLevel = currentLevel
        guard let nextLevel = currentLevel.degraded else {
            return nil
        }

        currentLevel = nextLevel
        consecutiveDegradationCount = 0

        let change = QualityChange(
            timestamp: Date(),
            from: previousLevel,
            to: nextLevel,
            reason: reason,
            direction: .reduced
        )
        qualityHistory.append(change)

        return QualityAdjustment(
            from: previousLevel,
            to: nextLevel,
            reason: reason,
            direction: .reduced
        )
    }

    private func restoreQuality(
        reason: String
    ) -> QualityAdjustment? {
        let previousLevel = currentLevel
        guard let nextLevel = currentLevel.improved else {
            return nil
        }

        currentLevel = nextLevel
        consecutiveImprovementCount = 0

        let change = QualityChange(
            timestamp: Date(),
            from: previousLevel,
            to: nextLevel,
            reason: reason,
            direction: .restored
        )
        qualityHistory.append(change)

        return QualityAdjustment(
            from: previousLevel,
            to: nextLevel,
            reason: reason,
            direction: .restored
        )
    }
}

/// A quality adjustment recommendation from the AdaptiveQualityManager.
public struct QualityAdjustment: Sendable, Equatable {
    /// Previous quality level.
    public let from: CaptureQualityLevel
    /// New quality level.
    public let to: CaptureQualityLevel
    /// Reason for the adjustment.
    public let reason: String
    /// Direction of the adjustment.
    public let direction: QualityDirection

    /// Creates a quality adjustment.
    ///
    /// - Parameters:
    ///   - from: Previous quality level.
    ///   - to: New quality level.
    ///   - reason: Reason for the adjustment.
    ///   - direction: Direction of the adjustment.
    public init(
        from: CaptureQualityLevel,
        to: CaptureQualityLevel,
        reason: String,
        direction: QualityDirection
    ) {
        self.from = from
        self.to = to
        self.reason = reason
        self.direction = direction
    }
}

/// A recorded quality change for history tracking.
public struct QualityChange: Sendable {
    /// When the change occurred.
    public let timestamp: Date
    /// Previous quality level.
    public let from: CaptureQualityLevel
    /// New quality level.
    public let to: CaptureQualityLevel
    /// Reason for the change.
    public let reason: String
    /// Direction of the change.
    public let direction: QualityDirection

    /// Creates a quality change record.
    ///
    /// - Parameters:
    ///   - timestamp: When the change occurred.
    ///   - from: Previous quality level.
    ///   - to: New quality level.
    ///   - reason: Reason for the change.
    ///   - direction: Direction of the change.
    public init(
        timestamp: Date,
        from: CaptureQualityLevel,
        to: CaptureQualityLevel,
        reason: String,
        direction: QualityDirection
    ) {
        self.timestamp = timestamp
        self.from = from
        self.to = to
        self.reason = reason
        self.direction = direction
    }
}

/// Direction of a quality adjustment.
public enum QualityDirection: String, Sendable, CaseIterable {
    /// Quality was reduced due to transport degradation.
    case reduced
    /// Quality was restored after transport recovery.
    case restored
}
