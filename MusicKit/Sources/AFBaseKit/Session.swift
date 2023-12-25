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
    
    public let nowPlaying: Track?
    public let queue: [Track]
    
    public let position: Double
    public let canSeek: Bool
    public let isPaused: Bool
    public let isMuted: Bool
    public let volumeLevel: Float
    public let repeatMode: RepeatMode
    
    public init(id: String, name: String, client: String, nowPlaying: Track?, queue: [Track], position: Double, canSeek: Bool, isPaused: Bool, isMuted: Bool, volumeLevel: Float, repeatMode: RepeatMode) {
        self.id = id
        self.name = name
        self.client = client
        self.nowPlaying = nowPlaying
        self.queue = queue
        self.position = position
        self.canSeek = canSeek
        self.isPaused = isPaused
        self.isMuted = isMuted
        self.volumeLevel = volumeLevel
        self.repeatMode = repeatMode
    }
}

public enum RepeatMode: Int, Equatable {
    case none = 0
    case track = 1
    case queue = 2
}

