// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation
import Testing

@testable import CaptureKit

private let defaultFrame = ScreenRect(x: 0, y: 0, width: 1920, height: 1080)

@Suite("ScreenCaptureContent")
struct ScreenCaptureContentTests {

    @Test("empty content is valid")
    func emptyContentIsValid() {
        let content = ScreenCaptureContent(displays: [], windows: [], applications: [])
        #expect(content.displays.isEmpty)
        #expect(content.windows.isEmpty)
        #expect(content.applications.isEmpty)
    }

    @Test("content with displays")
    func contentWithDisplays() {
        let display = ScreenDisplay(
            id: 1, width: 2560, height: 1440, frame: defaultFrame, isMain: true
        )
        let content = ScreenCaptureContent(
            displays: [display], windows: [], applications: []
        )
        #expect(content.displays.count == 1)
        #expect(content.displays.first?.id == 1)
    }

    @Test("content with windows")
    func contentWithWindows() {
        let window = ScreenWindow(
            id: 1, title: "Test",
            owningApplicationBundleID: "com.test",
            owningApplicationName: "Test",
            frame: defaultFrame, isOnScreen: true, windowLayer: 0
        )
        let content = ScreenCaptureContent(
            displays: [], windows: [window], applications: []
        )
        #expect(content.windows.count == 1)
        #expect(content.windows.first?.title == "Test")
    }

    @Test("content with applications")
    func contentWithApplications() {
        let app = ScreenApplication(id: "com.apple.Safari", applicationName: "Safari")
        let content = ScreenCaptureContent(
            displays: [], windows: [], applications: [app]
        )
        #expect(content.applications.count == 1)
        #expect(content.applications.first?.applicationName == "Safari")
    }

    @Test("ScreenDisplay is identifiable and equatable")
    func screenDisplayIdentifiableAndEquatable() {
        let display1 = ScreenDisplay(
            id: 1, width: 2560, height: 1440, frame: defaultFrame, isMain: true
        )
        let display2 = ScreenDisplay(
            id: 1, width: 2560, height: 1440, frame: defaultFrame, isMain: true
        )
        #expect(display1 == display2)
        #expect(display1.id == 1)
    }

    @Test("ScreenDisplay isMain property")
    func screenDisplayIsMainProperty() {
        let mainDisplay = ScreenDisplay(
            id: 1, width: 2560, height: 1440, frame: defaultFrame, isMain: true
        )
        let secondary = ScreenDisplay(
            id: 2, width: 1920, height: 1080, frame: defaultFrame, isMain: false
        )
        #expect(mainDisplay.isMain == true)
        #expect(secondary.isMain == false)
    }

    @Test("ScreenWindow stores title and owning app")
    func screenWindowStoresTitleAndOwningApp() {
        let window = ScreenWindow(
            id: 1, title: "My Window",
            owningApplicationBundleID: "com.test.app",
            owningApplicationName: "TestApp",
            frame: defaultFrame, isOnScreen: true, windowLayer: 0
        )
        #expect(window.title == "My Window")
        #expect(window.owningApplicationBundleID == "com.test.app")
        #expect(window.owningApplicationName == "TestApp")
    }

    @Test("ScreenWindow isOnScreen property")
    func screenWindowIsOnScreenProperty() {
        let visible = ScreenWindow(
            id: 1, title: "Visible",
            owningApplicationBundleID: "com.test",
            owningApplicationName: "Test",
            frame: defaultFrame, isOnScreen: true, windowLayer: 0
        )
        let hidden = ScreenWindow(
            id: 2, title: "Hidden",
            owningApplicationBundleID: "com.test",
            owningApplicationName: "Test",
            frame: defaultFrame, isOnScreen: false, windowLayer: 0
        )
        #expect(visible.isOnScreen == true)
        #expect(hidden.isOnScreen == false)
    }

    @Test("ScreenApplication is identifiable by bundleID")
    func screenApplicationIdentifiableByBundleID() {
        let app = ScreenApplication(id: "com.apple.Safari", applicationName: "Safari")
        #expect(app.id == "com.apple.Safari")
        #expect(app.applicationName == "Safari")
    }

    @Test("ScreenRect stores coordinates")
    func screenRectStoresCoordinates() {
        let rect = ScreenRect(x: 10, y: 20, width: 300, height: 400)
        #expect(rect.x == 10)
        #expect(rect.y == 20)
        #expect(rect.width == 300)
        #expect(rect.height == 400)
    }
}
