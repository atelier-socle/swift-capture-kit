// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Type of sample from the broadcast extension.
public enum BroadcastSampleType: String, Sendable, CaseIterable {
    /// Video frame.
    case video

    /// Application audio.
    case audioApp

    /// Microphone audio.
    case audioMic
}

/// Control messages sent from the main app to the extension.
public enum BroadcastControlMessage: String, Sendable, CaseIterable {
    /// Request the extension to stop broadcasting.
    case stop

    /// Request the extension to pause.
    case pause

    /// Request the extension to resume.
    case resume
}

/// A sample buffer received from the Broadcast Upload Extension.
public struct BroadcastSample: Sendable {
    /// The type of sample.
    public let sampleType: BroadcastSampleType

    /// The raw data.
    public let data: Data

    /// Timestamp.
    public let timestamp: TimeInterval

    /// Sequence number.
    public let sequenceNumber: Int64

    /// Creates a new broadcast sample.
    ///
    /// - Parameters:
    ///   - sampleType: The type of sample.
    ///   - data: The raw data.
    ///   - timestamp: The timestamp.
    ///   - sequenceNumber: The sequence number.
    public init(
        sampleType: BroadcastSampleType,
        data: Data,
        timestamp: TimeInterval,
        sequenceNumber: Int64
    ) {
        self.sampleType = sampleType
        self.data = data
        self.timestamp = timestamp
        self.sequenceNumber = sequenceNumber
    }
}

/// Inter-process communication channel between the main app and the
/// Broadcast Upload Extension via App Groups.
///
/// The extension process writes sample buffers to the shared container,
/// and the main app reads them via this channel.
///
/// Memory constraint: the extension process has a 50MB limit.
/// The IPC implementation must be lightweight and efficient.
@available(iOS 17.0, macOS 14.0, *)
public actor BroadcastIPCChannel {
    /// App Group identifier.
    public let appGroupID: String

    /// Whether the channel is currently connected.
    public private(set) var isConnected: Bool = false

    /// Maximum buffer size in bytes.
    public let maxBufferSize: Int

    /// Creates a new broadcast IPC channel.
    ///
    /// - Parameters:
    ///   - appGroupID: The App Group identifier.
    ///   - maxBufferSize: Maximum buffer size in bytes. Defaults to 5MB.
    public init(appGroupID: String, maxBufferSize: Int = 5_242_880) {
        self.appGroupID = appGroupID
        self.maxBufferSize = maxBufferSize
    }

    /// Connect to the shared container and begin reading.
    public func connect() async throws {
        guard !isConnected else { return }
        isConnected = true
    }

    /// Disconnect from the shared container.
    public func disconnect() async {
        isConnected = false
    }

    /// Read incoming sample buffers from the extension.
    ///
    /// Polls the shared App Group container for buffer files written by BroadcastRelay.
    ///
    /// - Returns: An asynchronous stream of broadcast samples.
    public func incomingBuffers() -> AsyncStream<BroadcastSample> {
        let groupID = appGroupID
        let connected = { @Sendable [weak self] in await self?.isConnected ?? false }

        return AsyncStream { continuation in
            let task = Task { @concurrent in
                var sequenceNumber: Int64 = 0

                while !Task.isCancelled {
                    guard await connected() else { break }

                    guard
                        let containerURL = FileManager.default.containerURL(
                            forSecurityApplicationGroupIdentifier: groupID)
                    else {
                        try? await Task.sleep(for: .milliseconds(10))
                        continue
                    }

                    let files =
                        (try? FileManager.default.contentsOfDirectory(
                            at: containerURL,
                            includingPropertiesForKeys: [.contentModificationDateKey]
                        )) ?? []

                    let bufferFiles = files.filter {
                        $0.pathExtension == "buf"
                    }.sorted {
                        $0.lastPathComponent < $1.lastPathComponent
                    }

                    for file in bufferFiles {
                        guard let data = try? Data(contentsOf: file) else {
                            continue
                        }
                        let name = file.deletingPathExtension().lastPathComponent
                        let sampleType = parseSampleType(from: name)
                        let timestamp = parseTimestamp(from: name)

                        let sample = BroadcastSample(
                            sampleType: sampleType,
                            data: data,
                            timestamp: timestamp,
                            sequenceNumber: sequenceNumber
                        )
                        continuation.yield(sample)
                        sequenceNumber += 1
                        try? FileManager.default.removeItem(at: file)
                    }

                    try? await Task.sleep(for: .milliseconds(10))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Write a control message to the extension (e.g., stop broadcasting).
    ///
    /// - Parameter message: The control message to send.
    /// - Throws: ``CaptureError/sourceNotAvailable(sourceType:reason:)`` if not connected.
    public func sendControlMessage(_ message: BroadcastControlMessage) async throws {
        guard isConnected else {
            throw CaptureError.sourceNotAvailable(
                sourceType: "broadcast",
                reason: "IPC channel is not connected"
            )
        }

        guard
            let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: appGroupID)
        else { return }

        let controlFile = containerURL.appendingPathComponent(
            "control_\(message.rawValue).msg")
        try? Data(message.rawValue.utf8).write(to: controlFile, options: .atomic)
    }

    // MARK: - Private

    private nonisolated func parseSampleType(from name: String) -> BroadcastSampleType {
        if name.hasPrefix("video") { return .video }
        if name.hasPrefix("audioApp") { return .audioApp }
        if name.hasPrefix("audioMic") { return .audioMic }
        return .video
    }

    private nonisolated func parseTimestamp(from name: String) -> TimeInterval {
        let parts = name.split(separator: "_")
        if parts.count >= 2, let ms = Int(parts[1]) {
            return TimeInterval(ms) / 1000.0
        }
        return 0.0
    }
}
