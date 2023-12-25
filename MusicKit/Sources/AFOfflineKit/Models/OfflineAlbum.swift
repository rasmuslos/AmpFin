//
//  OfflineAlbum.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFBaseKit

@Model
class OfflineAlbum {
    @Attribute(.unique) let id: String
    let name: String
    
    let overview: String?
    let genres: [String]
    
    let releaseDate: Date?
    let artists: [Item.ReducedArtist]
    
    var favorite: Bool
    var trackCount: Int
    
    init(id: String, name: String, overview: String?, genres: [String], releaseDate: Date?, artists: [Item.ReducedArtist], favorite: Bool, trackCount: Int) {
        self.id = id
        self.name = name
        self.overview = overview
        self.genres = genres
        self.releaseDate = releaseDate
        self.artists = artists
        self.favorite = favorite
        self.trackCount = trackCount
    }
}
