// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

extension Tag {
    /// Tests that require physical hardware (microphone, camera, etc.).
    @Tag static var hardware: Self
    /// Tests that require network access.
    @Tag static var network: Self
}
