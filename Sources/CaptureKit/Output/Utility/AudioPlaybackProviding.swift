// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Internal protocol abstracting audio playback for monitoring.
///
/// Enables dependency injection for testing: real implementation uses
/// AVAudioEngine, tests inject a mock that tracks calls.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
protocol AudioPlaybackProviding: Sendable {
    /// Prepare the playback engine for the given format.
    func prepare(format: AudioFormat) async throws

    /// Play audio data through the system output.
    func play(_ data: Data) async throws

    /// Set the playback volume (0.0–1.0).
    func setVolume(_ volume: Float) async

    /// Set the muted state.
    func setMuted(_ muted: Bool) async

    /// Stop playback and release resources.
    func stop() async
}
