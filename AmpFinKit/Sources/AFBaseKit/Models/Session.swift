//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation

@Observable
public class Session: Identifiable {
    public let id: String
    public let name: String
    
    public let client: String
    public let clientId: String
    
    public let nowPlaying: Track?
    
    public let position: Double
    public let canSeek: Bool
    public let canSetVolume: Bool
    
    public let isPaused: Bool
    public let isMuted: Bool
    
    public let volumeLevel: Float
    public let repeatMode: RepeatMode
    
    public init(id: String, name: String, client: String, clientId: String, nowPlaying: Track?, position: Double, canSeek: Bool, canSetVolume: Bool, isPaused: Bool, isMuted: Bool, volumeLevel: Float, repeatMode: RepeatMode) {
        self.id = id
        self.name = name
        self.client = client
        self.clientId = clientId
        self.nowPlaying = nowPlaying
        self.position = position
        self.canSeek = canSeek
        self.canSetVolume = canSetVolume
        self.isPaused = isPaused
        self.isMuted = isMuted
        self.volumeLevel = volumeLevel
        self.repeatMode = repeatMode
        
        // TODO: it seems like shuffled is not send at the moment, this should be implemented on the server...
        // also the send queue is useless
    }
}

public enum RepeatMode: Int, Equatable {
    case none = 0
    case track = 1
    case queue = 2
}

