//
//  Track.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

public class Track: Item {
    public let album: ReducedAlbum
    public let artists: [ReducedArtist]
    
    public let lufs: Float?
    public let index: Index
    
    public let runtime: Double
    public let playCount: Int
    public let releaseDate: Date?
    
    public init(id: String, name: String, cover: Cover? = nil, favorite: Bool, album: ReducedAlbum, artists: [ReducedArtist], lufs: Float?, index: Index, runtime: Double, playCount: Int, releaseDate: Date?) {
        self.album = album
        self.artists = artists
        self.lufs = lufs
        self.index = index
        self.runtime = runtime
        self.playCount = playCount
        self.releaseDate = releaseDate
        
        super.init(id: id, type: .track, name: name, cover: cover, favorite: favorite)
    }
}

// MARK: Helper

extension Track {
    public typealias Lyrics = [Double: String?]
    
    public struct Index: Comparable, Codable {
        public let index: Int
        public let disk: Int
        
        public init(index: Int, disk: Int) {
            self.index = index
            self.disk = disk
        }
        
        public static func < (lhs: Index, rhs: Index) -> Bool {
            if lhs.disk == rhs.disk {
                return lhs.index < rhs.index
            } else {
                return lhs.disk < rhs.disk
            }
        }
    }
    
    public struct ReducedAlbum {
        public let id: String
        public let name: String?
        public let artists: [ReducedArtist]
        
        public init(id: String, name: String?, artists: [ReducedArtist]) {
            self.id = id
            self.name = name
            self.artists = artists
        }
    }
}


// MARK: Convenience

extension Track {
    public var artistName: String {
        artists.map { $0.name }.joined(separator: String(localized: ", "))
    }
}
extension Track.ReducedAlbum {
    public var artistName: String {
        artists.map { $0.name }.joined(separator: String(localized: ", "))
    }
}
