//
//  JellyfinClient+Progress.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import Foundation

// MARK: Progress

public extension JellyfinClient {
    /// Report a playback start event to the server
    func reportPlaybackStarted(trackId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing", method: "POST", body: [
            "ItemId": trackId,
            "PositionTicks": 0,
        ]))
    }
    
    /// Report a progress event to the server
    func reportPlaybackProgress(trackId: String, positionSeconds: Double, paused: Bool, repeatMode: RepeatMode, shuffled: Bool, volume: Float) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing/progress", method: "POST", body: [
            "ItemId": trackId,
            "CanSeek": true,
            "IsPaused": paused,
            "VolumeLevel": Int(volume * 100),
            "IsMuted": volume == 0,
            "RepeatMode": repeatMode == .none ? "RepeatNone" : repeatMode == .track ? "RepeatOne" : "RepeatAll",
            "ShuffleMode": shuffled ? "Shuffle" : "Sorted",
            "PlaybackRate": 1,
            "PositionTicks": Int64(positionSeconds * 10_000_000),
        ]))
    }
    
    /// Report a playback ended event to the server
    func reportPlaybackStopped(trackId: String, positionSeconds: Double) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/Playing/Stopped", method: "POST", body: [
            "ItemId": trackId,
            "PositionTicks": Int64(positionSeconds * 10_000_000),
        ]))
    }
}
