// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// The central actor that manages the lifecycle of a media capture session,
/// coordinating sources, encoders, and outputs.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor CaptureSession {
    /// The current state of the capture session.
    public private(set) var state: CaptureSessionState = .idle

    /// The configuration applied to this capture session.
    public let configuration: CaptureSessionConfiguration

    /// Creates a new capture session with the given configuration.
    ///
    /// - Parameter configuration: The session configuration. Defaults to
    ///   ``CaptureSessionConfiguration/default``.
    public init(configuration: CaptureSessionConfiguration = .default) {
        self.configuration = configuration
    }
}
