//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation

@Observable
public final class Session: Identifiable, Codable {
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
    public let shuffled: Bool
    
    public init(id: String, name: String, client: String, clientId: String, nowPlaying: Track?, position: Double, canSeek: Bool, canSetVolume: Bool, isPaused: Bool, isMuted: Bool, volumeLevel: Float, repeatMode: RepeatMode, shuffled: Bool) {
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
        self.shuffled = shuffled
    }
    
    private enum CodingKeys: CodingKey {
        case id
        case name
        case client
        case clientId
        case nowPlaying
        case position
        case canSeek
        case canSetVolume
        case isPaused
        case isMuted
        case volumeLevel
        case repeatMode
        case shuffled
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.client = try container.decode(String.self, forKey: .client)
        self.clientId = try container.decode(String.self, forKey: .clientId)
        self.nowPlaying = try container.decodeIfPresent(Track.self, forKey: .nowPlaying)
        self.position = try container.decode(Double.self, forKey: .position)
        self.canSeek = try container.decode(Bool.self, forKey: .canSeek)
        self.canSetVolume = try container.decode(Bool.self, forKey: .canSetVolume)
        self.isPaused = try container.decode(Bool.self, forKey: .isPaused)
        self.isMuted = try container.decode(Bool.self, forKey: .isMuted)
        self.volumeLevel = try container.decode(Float.self, forKey: .volumeLevel)
        self.repeatMode = try container.decode(RepeatMode.self, forKey: .repeatMode)
        self.shuffled = try container.decode(Bool.self, forKey: .shuffled)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.client, forKey: .client)
        try container.encode(self.clientId, forKey: .clientId)
        try container.encodeIfPresent(self.nowPlaying, forKey: .nowPlaying)
        try container.encode(self.position, forKey: .position)
        try container.encode(self.canSeek, forKey: .canSeek)
        try container.encode(self.canSetVolume, forKey: .canSetVolume)
        try container.encode(self.isPaused, forKey: .isPaused)
        try container.encode(self.isMuted, forKey: .isMuted)
        try container.encode(self.volumeLevel, forKey: .volumeLevel)
        try container.encode(self.repeatMode, forKey: .repeatMode)
        try container.encode(self.shuffled, forKey: .shuffled)
    }
    
}

