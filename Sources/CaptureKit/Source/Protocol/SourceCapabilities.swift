// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Describes the availability of a capture source on the current platform and device.
public struct SourceAvailability: Sendable, Equatable {
    /// Whether the source is available on the current platform (macOS, iOS, visionOS).
    public let isAvailableOnCurrentPlatform: Bool

    /// Whether the source is available on the current hardware device.
    public let isAvailableOnCurrentDevice: Bool

    /// The system permissions required to use this source.
    public let requiredPermissions: [PermissionType]

    /// The minimum OS version required, if applicable.
    public let minimumOSVersion: String?

    /// Additional notes about availability or restrictions.
    public let notes: String?

    /// Creates a new source availability descriptor.
    ///
    /// - Parameters:
    ///   - isAvailableOnCurrentPlatform: Whether the source is available on this platform.
    ///   - isAvailableOnCurrentDevice: Whether the source is available on this device.
    ///   - requiredPermissions: The permissions required to use this source.
    ///   - minimumOSVersion: The minimum OS version, if any. Defaults to `nil`.
    ///   - notes: Additional notes. Defaults to `nil`.
    public init(
        isAvailableOnCurrentPlatform: Bool,
        isAvailableOnCurrentDevice: Bool,
        requiredPermissions: [PermissionType],
        minimumOSVersion: String? = nil,
        notes: String? = nil
    ) {
        self.isAvailableOnCurrentPlatform = isAvailableOnCurrentPlatform
        self.isAvailableOnCurrentDevice = isAvailableOnCurrentDevice
        self.requiredPermissions = requiredPermissions
        self.minimumOSVersion = minimumOSVersion
        self.notes = notes
    }

    /// A convenience value indicating the source is fully available with no restrictions.
    public static let available = SourceAvailability(
        isAvailableOnCurrentPlatform: true,
        isAvailableOnCurrentDevice: true,
        requiredPermissions: []
    )

    /// Creates an availability descriptor indicating the source is unavailable.
    ///
    /// - Parameter reason: A human-readable explanation of why the source is unavailable.
    /// - Returns: A ``SourceAvailability`` marked as unavailable with the given reason.
    public static func unavailable(reason: String) -> SourceAvailability {
        SourceAvailability(
            isAvailableOnCurrentPlatform: false,
            isAvailableOnCurrentDevice: false,
            requiredPermissions: [],
            notes: reason
        )
    }
}
