//
//  JellyfinClient+Methods.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

public extension JellyfinClient {
    /// Update the capabilities of the current session
    func setSessionCapabilities(allowRemoteControl: Bool) async throws {
        // TODO: add a DLNA profile
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/Capabilities/Full", method: "POST", body: [
            "PlayableMediaTypes": allowRemoteControl ? ["Audio"] : [],
            "SupportedCommands": [
                // "VolumeUp",
                // "VolumeDown",
                // "Mute",
                // "Unmute",
                // "ToggleMute",
                // "SetVolume",
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
        
        return response.filter {
            $0.Capabilities.PlayableMediaTypes.contains("Audio")
            && $0.Capabilities.SupportsMediaControl
            && $0.DeviceId != JellyfinClient.shared.clientId
        }.map(Session.convertFromJellyfin)
    }
    
    /// Issue a play state command without any parameters
    func issuePlayStateCommand(sessionId: String, command: PlayStateCommand) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Playing/\(command.rawValue)", method: "POST"))
    }
    
    /// Seek the playback of the session to the specified position
    func seek(sessionId: String, positionSeconds: Double) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Playing/Seek", method: "POST", query: [
            URLQueryItem(name: "seekPositionTicks", value: String(UInt64(positionSeconds * 10_000_000)))
        ]))
    }
    
    /// Set the session shuffle mode
    func setShuffleMode(sessionId: String, shuffled: Bool) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Command", method: "POST", body: [
            "Name": "SetShuffleQueue",
            "Arguments": [
                "ShuffleMode": shuffled ? "Shuffle" : "Sorted",
            ]
        ]))
    }
    
    /// Set the repeat shuffle mode
    func setRepeatMode(sessionId: String, repeatMode: RepeatMode) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Command", method: "POST", body: [
            "Name": "SetRepeatMode",
            "Arguments": [
                "RepeatMode": repeatMode == .none ? "RepeatNone" : repeatMode == .track ? "RepeatOne" : "RepeatAll",
            ],
        ]))
    }
    
    /// Start playback of the provided tracks
    func playTracks(sessionId: String, tracks: [Track], index: Int) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Playing", method: "POST", query: [
            URLQueryItem(name: "ItemIds", value: tracks.map { $0.id }.joined(separator: ",")),
            URLQueryItem(name: "StartIndex", value: String(index)),
            URLQueryItem(name: "PlayCommand", value: "PlayNow"),
        ]))
    }
    
    /// Add the provided tracks to the session queue
    func queueTracks(sessionId: String, tracks: [Track], queuePosition: PlayCommand) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Playing", method: "POST", query: [
            URLQueryItem(name: "ItemIds", value: tracks.map { $0.id }.joined(separator: ",")),
            URLQueryItem(name: "PlayCommand", value: queuePosition.rawValue),
        ]))
    }
    
    /// Set the output volume of the session
    func setOutputVolume(sessionId: String, volume: Float) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Command", method: "POST", body: [
            "Name": "SetVolume",
            "Arguments": [
                "Volume": String(Int(volume * 100)),
            ],
        ]))
    }
}
