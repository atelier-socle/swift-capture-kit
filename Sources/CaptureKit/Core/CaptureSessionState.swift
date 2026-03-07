// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Represents the lifecycle state of a capture session.
///
/// A capture session transitions through these states as it is configured,
/// started, paused, stopped, or encounters an error.
public enum CaptureSessionState: String, Sendable, CaseIterable {
    /// The session has not been started.
    case idle

    /// The session is setting up sources, encoders, and outputs.
    case configuring

    /// The session is fully configured and awaiting a start command.
    case ready

    /// The session start is in progress.
    case starting

    /// The session is actively capturing media.
    case capturing

    /// The session is paused but connections remain alive.
    case paused

    /// The session stop is in progress.
    case stopping

    /// The session encountered an error.
    case error

    /// Whether the session is actively processing media.
    ///
    /// Returns `true` when the state is ``capturing`` or ``paused``.
    public var isActive: Bool {
        switch self {
        case .capturing, .paused:
            return true
        default:
            return false
        }
    }

    /// Whether the session is in a terminal state that requires re-initialization.
    ///
    /// Returns `true` when the state is ``idle`` or ``error``.
    public var isTerminal: Bool {
        switch self {
        case .idle, .error:
            return true
        default:
            return false
        }
    }
}
