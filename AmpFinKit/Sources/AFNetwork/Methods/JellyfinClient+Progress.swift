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
            "RepeatMode": repeatMode == .queue ? "RepeatAll" : repeatMode == .track ? "RepeatOne" : "RepeatNone",
            "ShuffleMode": shuffled ? "Shuffle" : "Sorted",
            "PlaybackRate": 1,
            "PositionTicks": UInt64(position * 10_000_000),
        ]))
    }
    
    func playbackStopped(identifier: String, positionSeconds: Double, playSessionId: String?) async throws {
        var requestBody: [String : Any] = [
            "ItemId": identifier,
            "PositionTicks": Int64(positionSeconds * 10_000_000),
        ]
        
        if let playSessionId {
            requestBody["PlaySessionId"] = playSessionId
        }
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/Playing/Stopped", method: "POST", body: requestBody))
    }
}
