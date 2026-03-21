// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Detects CI environment to skip tests that require real-time audio
/// generation (ToneSource, SilenceSource) or physical hardware.
enum TestEnvironment {
    /// `true` when running inside a CI runner (GitHub Actions, etc.).
    static let isCI = ProcessInfo.processInfo.environment["CI"] != nil
}
