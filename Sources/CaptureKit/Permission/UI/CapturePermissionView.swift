// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import SwiftUI

/// SwiftUI view that displays permission status for capture-related permissions
/// and provides buttons to request or open Settings.
///
/// ```swift
/// CapturePermissionView(permissions: [.microphone, .camera])
/// ```
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public struct CapturePermissionView: View {
    /// Permissions to display.
    public let permissions: Set<CapturePermission>

    /// Current status for each permission.
    @State private var statuses: [CapturePermission: PermissionStatus] = [:]

    /// Whether a permission request is in progress.
    @State private var isRequesting: Bool = false

    /// Creates a new capture permission view.
    ///
    /// - Parameter permissions: The set of permissions to display.
    public init(permissions: Set<CapturePermission>) {
        self.permissions = permissions
    }

    /// The view body.
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(
                Array(permissions).sorted(by: { $0.rawValue < $1.rawValue }),
                id: \.self
            ) { permission in
                HStack {
                    Text(permission.rawValue.capitalized)
                        .font(.headline)
                    Spacer()
                    Text(statusText(for: permission))
                        .foregroundStyle(statusColor(for: permission))
                }
            }
        }
        .padding()
    }

    private func statusText(for permission: CapturePermission) -> String {
        switch statuses[permission] ?? .notDetermined {
        case .authorized: "Granted"
        case .denied: "Denied"
        case .restricted: "Restricted"
        case .provisional: "Provisional"
        case .notDetermined: "Not Requested"
        }
    }

    private func statusColor(for permission: CapturePermission) -> Color {
        switch statuses[permission] ?? .notDetermined {
        case .authorized: .green
        case .denied, .restricted: .red
        case .provisional: .orange
        case .notDetermined: .secondary
        }
    }
}
