// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Errors that can occur during capture session lifecycle, source management,
/// encoding, output delivery, and device interaction.
public enum CaptureError: Error, Sendable, CustomStringConvertible {
    // MARK: - Session

    /// The session has not been configured before attempting an operation.
    case sessionNotConfigured

    /// An attempt was made to start a session that is already running.
    case sessionAlreadyRunning

    /// An operation was attempted on a session that is not currently running.
    case sessionNotRunning

    /// The provided configuration is invalid.
    case invalidConfiguration(String)

    // MARK: - Source

    /// A requested source is not available.
    case sourceNotAvailable(sourceType: String, reason: String)

    /// The source is already capturing.
    case sourceAlreadyCapturing(sourceID: String)

    /// Configuration of a source failed.
    case sourceConfigurationFailed(sourceID: String, reason: String)

    /// The specified device could not be found.
    case deviceNotFound(deviceID: String)

    /// A device was unexpectedly disconnected.
    case deviceDisconnected(deviceID: String)

    /// The requested format is not supported.
    case formatNotSupported(format: String)

    // MARK: - Encoder

    /// The requested encoder is not available.
    case encoderNotAvailable(codec: String, reason: String)

    /// Configuration of an encoder failed.
    case encoderConfigurationFailed(codec: String, reason: String)

    /// Encoding a buffer or frame failed.
    case encodingFailed(codec: String, reason: String)

    /// The hardware encoder is currently in use by another process.
    case hardwareEncoderBusy

    /// The requested codec is not supported on the current platform.
    case codecNotSupportedOnPlatform(codec: String, platform: String)

    // MARK: - Output

    /// Preparation of an output failed.
    case outputPrepareFailed(outputID: String, reason: String)

    /// Writing to an output failed.
    case outputWriteFailed(outputID: String, reason: String)

    /// The file output directory is not writable.
    case fileOutputDirectoryNotWritable(path: String)

    /// Rotation of a file output failed.
    case fileOutputRotationFailed(reason: String)

    // MARK: - Permission

    /// A required permission was denied by the user or system.
    case permissionDenied(PermissionType)

    /// A required permission has not yet been determined.
    case permissionNotDetermined(PermissionType)

    // MARK: - Device

    /// No audio device is available on the system.
    case noAudioDeviceAvailable

    /// No video device is available on the system.
    case noVideoDeviceAvailable

    /// Creation of an aggregate audio device failed.
    case aggregateDeviceCreationFailed(reason: String)

    /// The device is in use by another process.
    case deviceInUseByAnotherProcess(deviceID: String)

    // MARK: - Format

    /// Sample rate conversion failed.
    case sampleRateConversionFailed

    /// Channel layout conversion failed.
    case channelLayoutConversionFailed

    /// Pixel format conversion failed.
    case pixelFormatConversionFailed

    /// Color space conversion failed.
    case colorSpaceConversionFailed

    /// A human-readable description of the error.
    public var description: String {
        switch self {
        // Session
        case .sessionNotConfigured:
            return "The capture session has not been configured."
        case .sessionAlreadyRunning:
            return "The capture session is already running."
        case .sessionNotRunning:
            return "The capture session is not running."
        case .invalidConfiguration(let detail):
            return "Invalid session configuration: \(detail)."

        // Source
        case .sourceNotAvailable(let sourceType, let reason):
            return "Source '\(sourceType)' is not available: \(reason)."
        case .sourceAlreadyCapturing(let sourceID):
            return "Source '\(sourceID)' is already capturing."
        case .sourceConfigurationFailed(let sourceID, let reason):
            return "Configuration of source '\(sourceID)' failed: \(reason)."
        case .deviceNotFound(let deviceID):
            return "Device '\(deviceID)' was not found."
        case .deviceDisconnected(let deviceID):
            return "Device '\(deviceID)' was disconnected."
        case .formatNotSupported(let format):
            return "Format '\(format)' is not supported."

        // Encoder
        case .encoderNotAvailable(let codec, let reason):
            return "Encoder for codec '\(codec)' is not available: \(reason)."
        case .encoderConfigurationFailed(let codec, let reason):
            return "Configuration of encoder '\(codec)' failed: \(reason)."
        case .encodingFailed(let codec, let reason):
            return "Encoding with codec '\(codec)' failed: \(reason)."
        case .hardwareEncoderBusy:
            return "The hardware encoder is busy and cannot accept new work."
        case .codecNotSupportedOnPlatform(let codec, let platform):
            return "Codec '\(codec)' is not supported on platform '\(platform)'."

        // Output
        case .outputPrepareFailed(let outputID, let reason):
            return "Preparation of output '\(outputID)' failed: \(reason)."
        case .outputWriteFailed(let outputID, let reason):
            return "Writing to output '\(outputID)' failed: \(reason)."
        case .fileOutputDirectoryNotWritable(let path):
            return "The file output directory is not writable: '\(path)'."
        case .fileOutputRotationFailed(let reason):
            return "File output rotation failed: \(reason)."

        // Permission
        case .permissionDenied(let permissionType):
            return "Permission denied for \(permissionType.rawValue)."
        case .permissionNotDetermined(let permissionType):
            return "Permission not yet determined for \(permissionType.rawValue)."

        // Device
        case .noAudioDeviceAvailable:
            return "No audio device is available."
        case .noVideoDeviceAvailable:
            return "No video device is available."
        case .aggregateDeviceCreationFailed(let reason):
            return "Aggregate device creation failed: \(reason)."
        case .deviceInUseByAnotherProcess(let deviceID):
            return "Device '\(deviceID)' is in use by another process."

        // Format
        case .sampleRateConversionFailed:
            return "Sample rate conversion failed."
        case .channelLayoutConversionFailed:
            return "Channel layout conversion failed."
        case .pixelFormatConversionFailed:
            return "Pixel format conversion failed."
        case .colorSpaceConversionFailed:
            return "Color space conversion failed."
        }
    }
}
