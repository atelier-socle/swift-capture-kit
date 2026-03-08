// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

@Suite("ProResEncoder Apple Silicon")
struct ProResEncoderAppleSiliconTests {

    @Test("isHardwareAccelerated is true")
    func isHardwareAccelerated() throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let encoder = ProResEncoder()

        #expect(encoder.isHardwareAccelerated == true)
    }

    @Test("supportedResolutions includes 4K")
    func supportedResolutionsIncludes4K() throws {
        guard #available(macOS 14.0, iOS 17.0, visionOS 1.0, *) else { return }

        let encoder = ProResEncoder()

        #expect(encoder.supportedResolutions.contains(.uhd4K))
    }
}
