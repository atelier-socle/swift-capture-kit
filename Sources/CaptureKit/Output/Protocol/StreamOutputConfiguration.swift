// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Transport-agnostic configuration for streaming outputs.
///
/// Used by consuming apps when creating bridge implementations
/// (HLSOutput, RTMPOutput, IcecastOutput, SRTOutput).
public struct StreamOutputConfiguration: Sendable, Equatable {
    /// Target URL or endpoint.
    public var endpoint: String

    /// Stream key or authentication token (if needed).
    public var streamKey: String?

    /// Whether to auto-reconnect on connection loss.
    public var autoReconnect: Bool

    /// Maximum reconnect attempts.
    public var maxReconnectAttempts: Int

    /// Reconnect delay in seconds.
    public var reconnectDelay: TimeInterval

    /// Connection timeout in seconds.
    public var connectionTimeout: TimeInterval

    /// Creates a stream output configuration.
    ///
    /// - Parameters:
    ///   - endpoint: The target URL or endpoint.
    ///   - streamKey: An optional stream key or authentication token.
    ///   - autoReconnect: Whether to auto-reconnect on connection loss.
    ///   - maxReconnectAttempts: Maximum reconnect attempts.
    ///   - reconnectDelay: Reconnect delay in seconds.
    ///   - connectionTimeout: Connection timeout in seconds.
    public init(
        endpoint: String,
        streamKey: String? = nil,
        autoReconnect: Bool = true,
        maxReconnectAttempts: Int = 5,
        reconnectDelay: TimeInterval = 2.0,
        connectionTimeout: TimeInterval = 10.0
    ) {
        self.endpoint = endpoint
        self.streamKey = streamKey
        self.autoReconnect = autoReconnect
        self.maxReconnectAttempts = maxReconnectAttempts
        self.reconnectDelay = reconnectDelay
        self.connectionTimeout = connectionTimeout
    }
}
