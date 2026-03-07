// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Testing

@testable import CaptureKit

@Suite("CinematicFocusSubject")
struct CinematicFocusSubjectTests {

    @Test("automatic case equality")
    func automaticCaseEquality() {
        let subject1 = CinematicFocusSubject.automatic
        let subject2 = CinematicFocusSubject.automatic
        #expect(subject1 == subject2)
    }

    @Test("person case with identifier")
    func personCaseWithIdentifier() {
        let subject1 = CinematicFocusSubject.person(identifier: 42)
        let subject2 = CinematicFocusSubject.person(identifier: 42)
        #expect(subject1 == subject2)

        let subject3 = CinematicFocusSubject.person(identifier: 99)
        #expect(subject1 != subject3)
    }

    @Test("person case with nil identifier")
    func personCaseWithNilIdentifier() {
        let subject1 = CinematicFocusSubject.person(identifier: nil)
        let subject2 = CinematicFocusSubject.person(identifier: nil)
        #expect(subject1 == subject2)

        let subject3 = CinematicFocusSubject.person(identifier: 1)
        #expect(subject1 != subject3)
    }

    @Test("point case equality")
    func pointCaseEquality() {
        let subject1 = CinematicFocusSubject.point(x: 0.5, y: 0.5)
        let subject2 = CinematicFocusSubject.point(x: 0.5, y: 0.5)
        #expect(subject1 == subject2)

        let subject3 = CinematicFocusSubject.point(x: 0.1, y: 0.9)
        #expect(subject1 != subject3)
    }

    @Test("object case equality")
    func objectCaseEquality() {
        let subject1 = CinematicFocusSubject.object(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        let subject2 = CinematicFocusSubject.object(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
        #expect(subject1 == subject2)

        let subject3 = CinematicFocusSubject.object(x: 0.5, y: 0.6, width: 0.7, height: 0.8)
        #expect(subject1 != subject3)
    }
}
