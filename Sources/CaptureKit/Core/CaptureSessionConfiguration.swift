// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// A policy that controls how a capture session adapts to changing system
/// conditions such as thermal pressure, CPU load, or network congestion.
public struct AdaptiveCapturePolicy: Sendable, Equatable {
    /// Whether adaptive quality adjustment is enabled.
    public var enabled: Bool

    /// The minimum quality grade the policy will allow before halting adaptation.
    public var minimumGrade: QualityGrade

    /// How quickly the policy reacts to changing conditions.
    public var responsiveness: Responsiveness

    /// Describes how quickly the adaptive policy reacts to changing conditions.
    public enum Responsiveness: String, Sendable, CaseIterable {
        /// Slow to react — favors stability over responsiveness.
        case conservative

        /// Balanced reaction time.
        case responsive

        /// Reacts as fast as possible to condition changes.
        case immediate
    }

    /// The default adaptive policy with responsive behavior and a fair minimum grade.
    public static let `default` = AdaptiveCapturePolicy(
        enabled: true,
        minimumGrade: .fair,
        responsiveness: .responsive
    )

    /// A disabled adaptive policy that performs no quality adjustments.
    public static let disabled = AdaptiveCapturePolicy(
        enabled: false,
        minimumGrade: .critical,
        responsiveness: .conservative
    )

    /// Creates an adaptive capture policy.
    ///
    /// - Parameters:
    ///   - enabled: Whether adaptive quality adjustment is enabled.
    ///   - minimumGrade: The minimum quality grade before halting adaptation.
    ///   - responsiveness: How quickly the policy reacts to condition changes.
    public init(enabled: Bool, minimumGrade: QualityGrade, responsiveness: Responsiveness) {
        self.enabled = enabled
        self.minimumGrade = minimumGrade
        self.responsiveness = responsiveness
    }
}

/// Configuration options for a capture session, controlling permissions,
/// reconnection behavior, statistics reporting, and adaptive quality.
public struct CaptureSessionConfiguration: Sendable, Equatable {
    /// Whether the session should automatically request required permissions
    /// when they have not yet been determined.
    public var automaticallyRequestPermissions: Bool

    /// Whether the session should attempt to reconnect when a device is
    /// unexpectedly disconnected.
    public var reconnectOnDeviceDisconnect: Bool

    /// The maximum number of reconnection attempts before giving up.
    public var maxReconnectAttempts: Int

    /// The interval, in seconds, between statistics update events.
    public var statisticsUpdateInterval: TimeInterval

    /// The adaptive quality policy applied to this session.
    public var adaptivePolicy: AdaptiveCapturePolicy

    /// The default configuration suitable for most capture scenarios.
    public static let `default` = CaptureSessionConfiguration(
        automaticallyRequestPermissions: true,
        reconnectOnDeviceDisconnect: true,
        maxReconnectAttempts: 3,
        statisticsUpdateInterval: 1.0,
        adaptivePolicy: .default
    )

    /// A configuration optimized for low-latency capture with fast
    /// adaptation and no reconnection.
    public static let lowLatency = CaptureSessionConfiguration(
        automaticallyRequestPermissions: true,
        reconnectOnDeviceDisconnect: false,
        maxReconnectAttempts: 0,
        statisticsUpdateInterval: 0.5,
        adaptivePolicy: AdaptiveCapturePolicy(
            enabled: true,
            minimumGrade: .good,
            responsiveness: .immediate
        )
    )

    /// A configuration optimized for high-quality capture with conservative
    /// adaptation and extended reconnection attempts.
    public static let highQuality = CaptureSessionConfiguration(
        automaticallyRequestPermissions: true,
        reconnectOnDeviceDisconnect: true,
        maxReconnectAttempts: 5,
        statisticsUpdateInterval: 2.0,
        adaptivePolicy: AdaptiveCapturePolicy(
            enabled: true,
            minimumGrade: .excellent,
            responsiveness: .conservative
        )
    )

    /// Creates a capture session configuration.
    ///
    /// - Parameters:
    ///   - automaticallyRequestPermissions: Whether to automatically request permissions.
    ///   - reconnectOnDeviceDisconnect: Whether to reconnect on device disconnect.
    ///   - maxReconnectAttempts: The maximum number of reconnection attempts.
    ///   - statisticsUpdateInterval: The interval between statistics updates.
    ///   - adaptivePolicy: The adaptive quality policy.
    public init(
        automaticallyRequestPermissions: Bool,
        reconnectOnDeviceDisconnect: Bool,
        maxReconnectAttempts: Int,
        statisticsUpdateInterval: TimeInterval,
        adaptivePolicy: AdaptiveCapturePolicy
    ) {
        self.automaticallyRequestPermissions = automaticallyRequestPermissions
        self.reconnectOnDeviceDisconnect = reconnectOnDeviceDisconnect
        self.maxReconnectAttempts = maxReconnectAttempts
        self.statisticsUpdateInterval = statisticsUpdateInterval
        self.adaptivePolicy = adaptivePolicy
    }
}
