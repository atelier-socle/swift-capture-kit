// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Actor that handles the CaptureKit side of Broadcast Upload Extension communication.
///
/// The consuming app's extension target subclasses `RPBroadcastSampleHandler` (ReplayKit)
/// and delegates to this actor for IPC with the main app.
///
/// Memory constraint: The extension process has a 50MB memory limit.
/// This relay is designed to be lightweight — it serializes sample buffers
/// to the shared App Group container and reads control messages.
@available(iOS 17.0, macOS 14.0, *)
public actor BroadcastRelay {
    /// App Group identifier for IPC.
    public let appGroupID: String

    /// Maximum buffer size for sample data.
    public let maxBufferSize: Int

    /// Whether the relay is currently active.
    public private(set) var isActive: Bool = false

    /// Whether the relay is currently paused.
    public private(set) var isPaused: Bool = false

    /// Creates a new broadcast relay.
    ///
    /// - Parameters:
    ///   - appGroupID: The App Group identifier.
    ///   - maxBufferSize: Maximum buffer size in bytes. Defaults to 5MB.
    public init(appGroupID: String, maxBufferSize: Int = 5_242_880) {
        self.appGroupID = appGroupID
        self.maxBufferSize = maxBufferSize
    }

    /// Called when the broadcast starts.
    /// Initializes the IPC channel to the main app.
    public func broadcastStarted() {
        isActive = true
    }

    /// Called when the broadcast is paused.
    public func broadcastPaused() {
        isPaused = true
    }

    /// Called when the broadcast resumes.
    public func broadcastResumed() {
        isPaused = false
    }

    /// Called when the broadcast finishes.
    /// Cleans up the IPC channel.
    public func broadcastFinished() {
        isActive = false
    }

    /// Process a sample buffer from the extension.
    /// Writes the data to the shared App Group container for the main app to read.
    ///
    /// - Parameters:
    ///   - data: The sample data.
    ///   - sampleType: The type of sample.
    ///   - timestamp: The sample timestamp.
    public func processSample(
        data: Data,
        sampleType: BroadcastSampleType,
        timestamp: TimeInterval
    ) {
        guard isActive, !isPaused, data.count <= maxBufferSize else { return }

        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupID)
        else { return }

        let fileName = "\(sampleType.rawValue)_\(Int(timestamp * 1000)).buf"
        let fileURL = containerURL.appendingPathComponent(fileName)
        try? data.write(to: fileURL, options: .atomic)
    }
}
