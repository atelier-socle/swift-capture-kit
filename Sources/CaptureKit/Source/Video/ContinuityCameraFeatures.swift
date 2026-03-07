// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Features available on Continuity Camera (iPhone as webcam).
public struct ContinuityCameraFeatures: Sendable, Equatable {
    /// Center Stage: AI-powered framing that follows the subject.
    public var centerStage: Bool

    /// Desk View: overhead view of desk surface.
    public var deskView: Bool

    /// Portrait mode: background blur.
    public var portraitMode: Bool

    /// Studio Light: enhanced lighting effect.
    public var studioLight: Bool

    /// Creates a new Continuity Camera features configuration.
    ///
    /// - Parameters:
    ///   - centerStage: Whether Center Stage is enabled. Defaults to `false`.
    ///   - deskView: Whether Desk View is enabled. Defaults to `false`.
    ///   - portraitMode: Whether Portrait mode is enabled. Defaults to `false`.
    ///   - studioLight: Whether Studio Light is enabled. Defaults to `false`.
    public init(
        centerStage: Bool = false,
        deskView: Bool = false,
        portraitMode: Bool = false,
        studioLight: Bool = false
    ) {
        self.centerStage = centerStage
        self.deskView = deskView
        self.portraitMode = portraitMode
        self.studioLight = studioLight
    }

    /// All features enabled.
    public static let allEnabled = ContinuityCameraFeatures(
        centerStage: true,
        deskView: false,
        portraitMode: true,
        studioLight: true
    )
}
