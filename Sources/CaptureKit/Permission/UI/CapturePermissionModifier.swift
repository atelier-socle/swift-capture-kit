// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import SwiftUI

/// View modifier that checks capture permissions before allowing interaction.
///
/// ```swift
/// CaptureView()
///     .capturePermissions([.microphone, .camera]) { results in
///         // Handle permission results
///     }
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public struct CapturePermissionModifier: ViewModifier {
    /// Permissions to check.
    public let permissions: Set<CapturePermission>

    /// Callback with permission results.
    public let onResult: @Sendable ([CapturePermission: PermissionStatus]) -> Void

    /// Applies the modifier to the content view.
    public func body(content: Content) -> some View {
        content
            .task {
                var results: [CapturePermission: PermissionStatus] = [:]
                for permission in permissions {
                    results[permission] = .notDetermined
                }
                onResult(results)
            }
    }
}

@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
extension View {
    /// Check capture permissions and receive results.
    ///
    /// - Parameters:
    ///   - permissions: The set of permissions to check.
    ///   - onResult: Callback with permission results.
    /// - Returns: A modified view.
    public func capturePermissions(
        _ permissions: Set<CapturePermission>,
        onResult:
            @escaping @Sendable (
                [CapturePermission: PermissionStatus]
            ) -> Void
    ) -> some View {
        modifier(
            CapturePermissionModifier(
                permissions: permissions, onResult: onResult))
    }
}
