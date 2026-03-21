// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("StreamingTypes", .timeLimit(.minutes(1)))
struct StreamingTypesTests {

    @Test("QualityGrade CaseIterable count is five")
    func qualityGradeCaseCount() {
        #expect(QualityGrade.allCases.count == 5)
    }

    @Test("QualityGrade Comparable ordering")
    func qualityGradeComparableOrdering() {
        #expect(QualityGrade.excellent > .good)
        #expect(QualityGrade.good > .fair)
        #expect(QualityGrade.fair > .poor)
        #expect(QualityGrade.poor > .critical)
    }

    @Test("StreamingTransportQuality init with recommendedBitrate nil")
    func transportQualityWithNilBitrate() {
        let quality = StreamingTransportQuality(score: 0.5, grade: .fair)
        #expect(quality.score == 0.5)
        #expect(quality.grade == .fair)
        #expect(quality.recommendedBitrate == nil)
    }

    @Test("StreamingTransportQuality init with recommendedBitrate value")
    func transportQualityWithBitrate() {
        let quality = StreamingTransportQuality(
            score: 0.95,
            grade: .excellent,
            recommendedBitrate: 10_000_000
        )
        #expect(quality.score == 0.95)
        #expect(quality.grade == .excellent)
        #expect(quality.recommendedBitrate == 10_000_000)
    }
}
