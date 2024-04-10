//
//  OfflineAlbum.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFBase

@Model
final class OfflineAlbum: OfflineParent {
    @Attribute(.unique) let id: String
    let name: String
    
    let overview: String?
    let genres: [String]
    
    let releaseDate: Date?
    let artists: [Item.ReducedArtist]
    
    var favorite: Bool
    
    var childrenIds: [String]
    
    init(id: String, name: String, overview: String?, genres: [String], releaseDate: Date?, artists: [Item.ReducedArtist], favorite: Bool, childrenIds: [String]) {
        self.id = id
        self.name = name
        self.overview = overview
        self.genres = genres
        self.releaseDate = releaseDate
        self.artists = artists
        self.favorite = favorite
        self.childrenIds = childrenIds
    }
}
