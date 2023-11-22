//
//  Messages.swift
//
//
//  Created by Rasmus Krämer on 15.11.23.
//

import Foundation
import MusicKit

// MARK: Authentication

public struct AuthenticationMessage: SendableMessage {
    let server: String
    let userId: String
    let token: String
    
    public init(server: String, userId: String, token: String) {
        self.server = server
        self.userId = userId
        self.token = token
    }
    
    func getMessage() -> Message {
        Message(type: .authentication, payload: [
            "server": server,
            "userId": userId,
            "token": token,
        ])
    }
    func action() {
        #if os(watchOS)
        try! JellyfinClient.shared.setServerUrl(server)
        JellyfinClient.shared.setUserId(userId)
        JellyfinClient.shared.setToken(token)
        
        Task { @MainActor in
            NotificationCenter.default.post(name: ConnectivityKit.authenticated, object: nil)
        }
        #endif
    }
    
    static func parse(payload: Payload) throws -> AuthenticationMessage {
        if let server = payload["server"] as? String, let userId = payload["userId"] as? String, let token = payload["token"] as? String {
            return AuthenticationMessage(server: server, userId: userId, token: token)
        } else {
            throw ConnectivityError.parseFailed
        }
    }
}

// MARK: Now playing

public struct NowPlayingMessage: SendableMessage {
    let callback: ((_ trackId: String, _ name: String, _ artist: String, _ cover: URL?, _ favorite: Bool) -> Void)?
    
    public init(callback: ((_: String, _: String, _: String, _: URL?, _: Bool) -> Void)?) {
        self.callback = callback
    }
    
    func getMessage() -> Message {
        Message(type: .nowPlaying, payload: [:])
    }
    
    func action() {
    }
    
    static func parse(payload: Payload) throws -> NowPlayingMessage {
        return NowPlayingMessage(callback: nil)
    }
    
    func replyHandler(payload: Payload) {
        if let trackId = payload["trackId"] as? String,
           let name = payload["name"] as? String,
           let artist = payload["artist"] as? String,
           let cover = payload["cover"] as? String,
           let favorite = payload["favorite"] as? Bool {
            callback?(trackId, name, artist, URL(string: cover), favorite)
        }
    }
    
    func reply() -> Payload? {
        if let nowPlaying = AudioPlayer.shared.nowPlaying {
            return [
                "trackId": nowPlaying.id,
                "name": nowPlaying.name,
                "artist": nowPlaying.artistName,
                "cover": nowPlaying.cover?.url.absoluteString as Any,
                "favorite": nowPlaying.favorite,
            ]
        }
        
        return nil
    }
}
