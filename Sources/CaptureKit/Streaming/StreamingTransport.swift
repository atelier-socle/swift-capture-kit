// SPDX-License-Identifier: Apache-2.0
// Copyright 2026 Atelier Socle SAS

/// Transport-agnostic interface for sending encoded media to a remote
/// endpoint.  Concrete implementations live in consuming apps or bridge
/// packages (e.g. RTMPTransport, SRTTransport, HLSTransport).
public protocol StreamingTransport: Sendable {

    /// Establish the connection to the remote endpoint.
    func connect() async throws

    /// Send codec configuration data before the first media packets.
    /// Called once per track (video and/or audio) after the pipeline
    /// extracts parameter sets.
    func sendConfiguration(_ config: StreamConfiguration) async throws

    /// Send a single media packet (video frame or audio buffer).
    func send(_ packet: MediaPacket) async throws

    /// Gracefully disconnect from the remote endpoint.
    func disconnect() async throws
}
