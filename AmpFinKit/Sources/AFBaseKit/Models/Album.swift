//
//  Album.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

/// Album containing multiple tracks
public class Album: Item {
    /// Description of the album
    public let overview: String?
    /// Genres the albums is assigned to
    public let genres: [String]
    
    /// Date when the album was first released
    public let releaseDate: Date?
    /// All artists that are credited with making the album. Does not include featured artists
    public let artists: [ReducedArtist]
    
    /// Amount of times the user has played the album
    public let playCount: Int
    
    public init(id: String, name: String, cover: Cover? = nil, favorite: Bool, overview: String?, genres: [String], releaseDate: Date?, artists: [ReducedArtist], playCount: Int) {
        self.overview = overview
        self.genres = genres
        self.releaseDate = releaseDate
        self.artists = artists
        self.playCount = playCount
        
        super.init(id: id, type: .album, name: name, cover: cover, favorite: favorite)
    }
    
    public enum CodingKeys: String, CodingKey {
        case overview
        case genres
        case releaseDate
        case artists
        case playCount
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.genres = try container.decodeIfPresent([String].self, forKey: .genres) ?? []
        self.releaseDate = try container.decodeIfPresent(Date.self, forKey: .releaseDate)
        self.artists = try container.decodeIfPresent([ReducedArtist].self, forKey: .artists) ?? []
        self.playCount = try container.decode(Int.self, forKey: .playCount)
        
        try super.init(from: decoder)
    }
}

// MARK: Convenience

extension Album {
    /// Comma separated string of all artist names
    public var artistName: String {
        get {
            artists.map { $0.name }.joined(separator: String(localized: ", "))
        }
    }
}
