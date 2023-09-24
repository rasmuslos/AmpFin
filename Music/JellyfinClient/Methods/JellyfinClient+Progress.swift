//
//  JellyfinClient+Progress.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import Foundation

// MARK: Progress

extension JellyfinClient {
    func reportPlaybackStarted(trackId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing", method: "POST", body: [
            "ItemId": trackId,
            "PositionTicks": 0,
        ]))
    }
    
    func reportPlaybackProgress(trackId: String, positionSeconds: Double, paused: Bool) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing/progress", method: "POST", body: [
            "ItemId": trackId,
            "IsPaused": paused,
            "PositionTicks": Int64(positionSeconds * 10_000_000),
        ]))
    }
    
    func reportPlaybackStopped(trackId: String, positionSeconds: Double) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/Playing/Stopped", method: "POST", body: [
            "ItemId": trackId,
            "PositionTicks": Int64(positionSeconds * 10_000_000),
        ]))
    }
}

// MARK: Favorite

extension JellyfinClient {
    func setFavorite(itemId: String, favorite: Bool) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "FavoriteItems/\(itemId)", method: favorite ? "POST" : "DELETE", userPrefix: true))
    }
}
