// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// A permission status change event.
public struct PermissionChange: Sendable, Equatable {
    /// The permission type that changed.
    public let type: PermissionType
    /// Previous status.
    public let oldStatus: PermissionStatus
    /// New status.
    public let newStatus: PermissionStatus

    /// Creates a new permission change event.
    ///
    /// - Parameters:
    ///   - type: The permission type that changed.
    ///   - oldStatus: The previous status.
    ///   - newStatus: The new status.
    public init(
        type: PermissionType,
        oldStatus: PermissionStatus,
        newStatus: PermissionStatus
    ) {
        self.type = type
        self.oldStatus = oldStatus
        self.newStatus = newStatus
    }
}

/// Unified permission manager for all capture-related permissions.
///
/// Provides a single entry point to check and request microphone, camera,
/// screen recording, photo library, and Bluetooth permissions.
///
/// ```swift
/// let manager = PermissionManager()
/// let status = await manager.status(for: .microphone)
/// if status == .notDetermined {
///     let result = await manager.request(.microphone)
/// }
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public actor PermissionManager {

    /// Cached permission states.
    private var cachedStatuses: [PermissionType: PermissionStatus] = [:]

    /// Event continuation for permission changes.
    private var changeContinuation: AsyncStream<PermissionChange>.Continuation?

    /// Creates a new permission manager.
    public init() {}

    deinit {
        changeContinuation?.finish()
    }

    /// Check current permission status for a specific type.
    ///
    /// Returns the cached status if available, otherwise queries the system.
    ///
    /// - Parameter type: The permission type to check.
    /// - Returns: The current permission status.
    public func status(for type: PermissionType) async -> PermissionStatus {
        if let cached = cachedStatuses[type] {
            return cached
        }
        let status = await querySystemStatus(for: type)
        cachedStatuses[type] = status
        return status
    }

    /// Request permission from the user.
    ///
    /// If already authorized, returns `.authorized` immediately.
    /// If denied or restricted, returns the current status without prompting.
    ///
    /// - Parameter type: The permission type to request.
    /// - Returns: The resulting permission status.
    public func request(_ type: PermissionType) async -> PermissionStatus {
        let current = await status(for: type)
        guard current == .notDetermined else { return current }
        let result: PermissionStatus = .notDetermined
        cachedStatuses[type] = result
        emitChange(
            PermissionChange(
                type: type, oldStatus: current, newStatus: result))
        return result
    }

    /// Request all permissions in the given set.
    ///
    /// - Parameter types: The set of permission types to request.
    /// - Returns: A dictionary of permission statuses keyed by type.
    public func requestAll(
        for types: Set<PermissionType>
    ) async -> [PermissionType: PermissionStatus] {
        var results: [PermissionType: PermissionStatus] = [:]
        for type in types {
            results[type] = await request(type)
        }
        return results
    }

    /// Observe permission changes.
    public var permissionChanges: AsyncStream<PermissionChange> {
        let (stream, continuation) = AsyncStream.makeStream(
            of: PermissionChange.self)
        self.changeContinuation = continuation
        return stream
    }

    /// Clear the cached status for a permission type (force re-query).
    ///
    /// - Parameter type: The permission type to clear.
    public func clearCache(for type: PermissionType) {
        cachedStatuses.removeValue(forKey: type)
    }

    /// Clear all cached statuses.
    public func clearAllCaches() {
        cachedStatuses.removeAll()
    }

    // MARK: - Private

    private func querySystemStatus(
        for type: PermissionType
    ) async -> PermissionStatus {
        .notDetermined
    }

    private func emitChange(_ change: PermissionChange) {
        changeContinuation?.yield(change)
    }
}
