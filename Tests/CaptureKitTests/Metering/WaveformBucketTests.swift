// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("WaveformBucket")
struct WaveformBucketTests {

    @Test("stores min max rms")
    func storesValues() {
        let bucket = WaveformBucket(min: -0.8, max: 0.9, rms: 0.4)
        #expect(bucket.min == -0.8)
        #expect(bucket.max == 0.9)
        #expect(bucket.rms == 0.4)
    }

    @Test("amplitude is max minus min")
    func amplitude() {
        let bucket = WaveformBucket(min: -0.5, max: 0.5, rms: 0.3)
        #expect(bucket.amplitude == 1.0)
    }

    @Test("normalizedAmplitude is amplitude / 2")
    func normalizedAmplitude() {
        let bucket = WaveformBucket(min: -0.5, max: 0.5, rms: 0.3)
        #expect(bucket.normalizedAmplitude == 0.5)
    }

    @Test("silence bucket has zero amplitude")
    func silenceBucket() {
        let bucket = WaveformBucket(min: 0, max: 0, rms: 0)
        #expect(bucket.amplitude == 0)
        #expect(bucket.normalizedAmplitude == 0)
    }

    @Test("Equatable conformance")
    func equatable() {
        let a = WaveformBucket(min: -0.5, max: 0.5, rms: 0.3)
        let b = WaveformBucket(min: -0.5, max: 0.5, rms: 0.3)
        #expect(a == b)
    }
}
