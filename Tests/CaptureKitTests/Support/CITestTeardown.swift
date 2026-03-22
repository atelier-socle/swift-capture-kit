// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

import Foundation

/// Forces CFRunLoopStop on the main run loop at exit.
///
/// Apple frameworks (AVFoundation, ScreenCaptureKit, VideoToolbox) register
/// CFRunLoop observers when their dylibs load. On CI without hardware, these
/// observers never resolve → the main thread stays blocked in CFRunLoopRun →
/// dispatch_group_wait never completes → the process never exits.
///
/// This top-level initializer registers an atexit handler that stops the main
/// run loop, allowing the process to exit cleanly.
#if canImport(CoreFoundation)
    private let _ciTeardown: Void = {
        atexit {
            CFRunLoopStop(CFRunLoopGetMain())
        }
    }()
#endif
