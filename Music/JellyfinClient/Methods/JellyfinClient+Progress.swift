//
//  JellyfinClient+Progress.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import Foundation

extension JellyfinClient {
    func reportPlaybackStopped(itemId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing/stopped", method: "POST", body: [
            "ItemId": itemId,
            // "PositionTicks": positionSeconds * 10_000_000,
        ]))
    }
    
    func reportPlaybackProgress(itemId: String, positionSeconds: Double, paused: Bool) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing/progress", method: "POST", body: [
            "ItemId": itemId,
            "PositionTicks": positionSeconds * 10_000_000,
            "IsPaused": paused,
        ]))
    }
    
    func reportPlaybackStarted(itemId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing", method: "POST", body: [
            "ItemId": itemId,
            "PositionTicks": 0,
        ]))
    }
}
