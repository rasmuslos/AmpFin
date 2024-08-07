//
//  Track.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import SwiftUI

public final class Track: Item {
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
    
    private enum CodingKeys: String, CodingKey {
        case album
        case artists
        case lufs
        case index
        case runtime
        case playCount
        case releaseDate
        case playlistItemId
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.album = try container.decode(ReducedAlbum.self, forKey: .album)
        self.artists = try container.decode([ReducedArtist].self, forKey: .artists)
        self.lufs = try container.decodeIfPresent(Float.self, forKey: .lufs)
        self.index = try container.decode(Index.self, forKey: .index)
        self.runtime = try container.decode(Double.self, forKey: .runtime)
        self.playCount = try container.decode(Int.self, forKey: .playCount)
        self.releaseDate = try container.decodeIfPresent(Date.self, forKey: .releaseDate)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.album, forKey: .album)
        try container.encode(self.artists, forKey: .artists)
        try container.encodeIfPresent(self.lufs, forKey: .lufs)
        try container.encode(self.index, forKey: .index)
        try container.encode(self.runtime, forKey: .runtime)
        try container.encode(self.playCount, forKey: .playCount)
        try container.encodeIfPresent(self.releaseDate, forKey: .releaseDate)
        
        try super.encode(to: encoder)
    }
}

extension Track: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .audio)
    }
}

public extension Track {
    typealias Lyrics = [Double: String?]
    
    struct Index: Comparable, Codable {
        public let index: Int
        public let disk: Int
        
        public init(index: Int, disk: Int) {
            self.index = index
            self.disk = disk
        }
        
        public static func <(lhs: Index, rhs: Index) -> Bool {
            if lhs.disk == rhs.disk {
                return lhs.index < rhs.index
            } else {
                return lhs.disk < rhs.disk
            }
        }
    }
    
    struct ReducedAlbum: Codable {
        public let id: String
        public let name: String?
        public let artists: [ReducedArtist]
        
        public init(id: String, name: String?, artists: [ReducedArtist]) {
            self.id = id
            self.name = name
            self.artists = artists
        }
    }
    
    struct MediaInfo {
        public var codec: String?
        public var lossless: Bool?
        
        public var bitrate: Int?
        public let bitDepth: Int?
        public let sampleRate: Int?
        
        public init(codec: String?, lossless: Bool?, bitrate: Int?, bitDepth: Int?, sampleRate: Int?) {
            self.codec = codec
            self.lossless = lossless
            self.bitrate = bitrate
            self.bitDepth = bitDepth
            self.sampleRate = sampleRate
        }
    }
}

public extension Track {
    var artistName: String? {
        guard !artists.isEmpty else {
            return nil
        }
        
        return artists.map { $0.name }.joined(separator: String(localized: ", "))
    }
}

public extension Track.ReducedAlbum {
    var artistName: String? {
        guard !artists.isEmpty else {
            return nil
        }
        
        return artists.map { $0.name }.joined(separator: String(localized: ", "))
    }
}
