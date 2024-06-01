//
//  Album.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

public final class Album: Item {
    public let overview: String?
    public let genres: [String]
    
    public let releaseDate: Date?
    public let artists: [ReducedArtist]
    
    public let playCount: Int
    public let lastPlayed: Date?
    
    public init(id: String, name: String, cover: Cover? = nil, favorite: Bool, overview: String?, genres: [String], releaseDate: Date?, artists: [ReducedArtist], playCount: Int, lastPlayed: Date?) {
        self.overview = overview
        self.genres = genres
        self.releaseDate = releaseDate
        self.artists = artists
        self.playCount = playCount
        self.lastPlayed = lastPlayed
        
        super.init(id: id, type: .album, name: name, cover: cover, favorite: favorite)
    }
    
    private enum CodingKeys: String, CodingKey {
        case overview
        case genres
        case releaseDate
        case artists
        case playCount
        case lastPlayed
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.genres = try container.decodeIfPresent([String].self, forKey: .genres) ?? []
        self.releaseDate = try container.decodeIfPresent(Date.self, forKey: .releaseDate)
        self.artists = try container.decodeIfPresent([ReducedArtist].self, forKey: .artists) ?? []
        self.playCount = try container.decode(Int.self, forKey: .playCount)
        self.lastPlayed = try container.decodeIfPresent(Date.self, forKey: .lastPlayed)
        
        try super.init(from: decoder)
    }
}

public extension Album {
    var artistName: String? {
        get {
            guard !artists.isEmpty else {
                return nil
            }
            
            return artists.map { $0.name }.joined(separator: String(", "))
        }
    }
}
