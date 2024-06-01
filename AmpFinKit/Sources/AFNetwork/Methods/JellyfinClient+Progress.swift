//
//  JellyfinClient+Progress.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import Foundation
import AFFoundation

public extension JellyfinClient {
    func playbackStarted(identifier: String, queueIds: [String]) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing", method: "POST", body: [
            "PositionTicks": 0,
            "ItemId": identifier,
            "NowPlayingQueue": queueIds.enumerated().map { [
                "Id": $1,
                "PlaylistItemId": "playlistItem\($0)"
            ] }
        ]))
    }
    
    func progress(identifier: String, position: Double, paused: Bool, repeatMode: RepeatMode, shuffled: Bool, volume: Float) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing/progress", method: "POST", body: [
            "ItemId": identifier,
            "CanSeek": true,
            "IsPaused": paused,
            "VolumeLevel": Int(volume * 100),
            "IsMuted": volume == 0,
            "RepeatMode": repeatMode == .none ? "RepeatNone" : repeatMode == .track ? "RepeatOne" : "RepeatAll",
            "ShuffleMode": shuffled ? "Shuffle" : "Sorted",
            "PlaybackRate": 1,
            "PositionTicks": Int64(position * 10_000_000),
        ]))
    }
    
    func playbackStopped(identifier: String, positionSeconds: Double) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/Playing/Stopped", method: "POST", body: [
            "ItemId": identifier,
            "PositionTicks": Int64(positionSeconds * 10_000_000),
        ]))
    }
}
