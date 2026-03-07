// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// A protocol combining both audio and video capture source capabilities.
@available(macOS 14.0, iOS 17.0, visionOS 1.0, *)
public protocol MediaSource: AudioSource, VideoSource {}
