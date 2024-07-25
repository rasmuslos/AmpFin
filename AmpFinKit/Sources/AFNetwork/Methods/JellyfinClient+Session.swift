//
//  JellyfinClient+Methods.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AFFoundation
import CryptoKit

public extension JellyfinClient {
    func update(allowRemoteControl: Bool) async throws {
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
            "SupportsMediaControl": allowRemoteControl,
            "AppStoreUrl": "https://apps.apple.com/app/ampfin/id6473753735",
        ]))
    }
    
    func controllableSessions() async -> [Session] {
        guard let response = try? await request(ClientRequest<[JellyfinSession]>(path: "Sessions", method: "GET", query: [
            URLQueryItem(name: "ControllableByUserId", value: userId)
        ])) else {
            return []
        }
        
        return response.filter {
            $0.Capabilities.PlayableMediaTypes.contains("Audio")
            && $0.Capabilities.SupportsMediaControl
            && $0.DeviceId != JellyfinClient.shared.clientId
        }.map(Session.init)
    }
    
    func update(sessionId: String, command: PlayStateCommand) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Playing/\(command.rawValue)", method: "POST"))
    }
    
    func update(sessionId: String, positionSeconds: Double) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Playing/Seek", method: "POST", query: [
            URLQueryItem(name: "seekPositionTicks", value: String(UInt64(positionSeconds * 10_000_000)))
        ]))
    }
    
    func update(sessionId: String, shuffled: Bool) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Command", method: "POST", body: [
            "Name": "SetShuffleQueue",
            "Arguments": [
                "ShuffleMode": shuffled ? "Shuffle" : "Sorted",
            ]
        ]))
    }
    
    func update(sessionId: String, repeatMode: RepeatMode) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Command", method: "POST", body: [
            "Name": "SetRepeatMode",
            "Arguments": [
                "RepeatMode": repeatMode == .none ? "RepeatNone" : repeatMode == .track ? "RepeatOne" : "RepeatAll",
            ],
        ]))
    }
    
    func update(sessionId: String, volume: Float) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Command", method: "POST", body: [
            "Name": "SetVolume",
            "Arguments": [
                "Volume": String(Int(volume * 100)),
            ],
        ]))
    }
    
    func play(sessionId: String, tracks: [Track], index: Int) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Playing", method: "POST", query: [
            URLQueryItem(name: "ItemIds", value: tracks.map { $0.id }.joined(separator: ",")),
            URLQueryItem(name: "StartIndex", value: String(index)),
            URLQueryItem(name: "PlayCommand", value: "PlayNow"),
        ]))
    }
    
    func queue(sessionId: String, tracks: [Track], queuePosition: PlayCommand) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Sessions/\(sessionId)/Playing", method: "POST", query: [
            URLQueryItem(name: "ItemIds", value: tracks.map { $0.id }.joined(separator: ",")),
            URLQueryItem(name: "PlayCommand", value: queuePosition.rawValue),
        ]))
    }
}

public extension JellyfinClient {
    static func sessionID(itemId: String, bitrate: Int?) -> String {
        let digest = Insecure.MD5.hash(data: Data("\(itemId)::\(bitrate ?? -1)".utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
