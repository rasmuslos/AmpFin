//
//  JellyfinClient+Methods.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

public extension JellyfinClient {
    /// Update the capabilities of the current session
    func setSessionCapabilities() async throws {
        // TODO: add a DLNA profile
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/Capabilities/Full", method: "POST", body: [
            "PlayableMediaTypes": [
                "Audio"
            ],
            "SupportedCommands": [
                "VolumeUp",
                "VolumeDown",
                "Mute",
                "Unmute",
                "ToggleMute",
                "SetVolume",
                "SetRepeatMode",
                "PlayMediaSource",
                "SetShuffleQueue",
                "PlayState",
                "PlayNext",
                "Play",
            ],
            "SupportsMediaControl": true,
            "AppStoreUrl": "about:blank",
        ]))
    }
    
    /// Get all sessions that are controllable by the client
    func getControllableSessions() async -> [Session] {
        guard let response = try? await request(ClientRequest<[JellyfinSession]>(path: "Sessions", method: "GET", query: [
            URLQueryItem(name: "ControllableByUserId", value: userId)
        ])) else {
            return []
        }
        
        return response.filter { $0.Capabilities.PlayableMediaTypes.contains("Audio") && $0.Capabilities.SupportsMediaControl }.map(Session.convertFromJellyfin)
    }
}
