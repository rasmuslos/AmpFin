//
//  JellyfinClient+Progress.swift
//  Music
//
//  Created by Rasmus Krämer on 07.09.23.
//

import Foundation

extension JellyfinClient {
    func reportPlaybackStopped(trackId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing/stopped", method: "POST", body: [
            "ItemId": trackId,
            // "PositionTicks": positionSeconds * 10_000_000,
        ]))
    }
    
    func reportPlaybackProgress(trackId: String, positionSeconds: Double, paused: Bool) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing/progress", method: "POST", body: [
            "ItemId": trackId,
            "PositionTicks": positionSeconds * 10_000_000,
            "IsPaused": paused,
        ]))
    }
    
    func reportPlaybackStarted(trackId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "sessions/playing", method: "POST", body: [
            "ItemId": trackId,
            "PositionTicks": 0,
        ]))
    }
}
