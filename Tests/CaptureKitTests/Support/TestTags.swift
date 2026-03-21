// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

extension Tag {
    /// Tests that require physical hardware (microphone, camera, etc.).
    @Tag static var hardware: Self
    /// Tests that require network access.
    @Tag static var network: Self
    /// Showcase tests that document public API usage patterns.
    @Tag static var showcase: Self
    /// End-to-end tests that exercise full pipelines.
    @Tag static var e2e: Self
}
