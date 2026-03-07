// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// H.264 entropy coding mode.
public enum H264EntropyMode: String, Sendable, CaseIterable {
    /// Context-Adaptive Variable-Length Coding — Baseline compatible, faster.
    case cavlc
    /// Context-Adaptive Binary Arithmetic Coding — higher efficiency, Main/High.
    case cabac
}
