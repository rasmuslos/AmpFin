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
        print("d")
        
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
