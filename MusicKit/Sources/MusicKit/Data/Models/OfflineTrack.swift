//
//  OfflineTrack.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData

@Model
class OfflineTrack {
    @Attribute(.unique) let id: String
    let name: String
    let sortName: String
    
    let index: Track.Index
    let releaseDate: Date?
    
    @Relationship
    var album: OfflineAlbum!
    let artists: [Item.ReducedArtist]
    
    var favorite: Bool
    var downloadId: Int?
    
    init(id: String, name: String, sortName: String, index: Track.Index, releaseDate: Date?, artists: [Item.ReducedArtist], favorite: Bool, downloadId: Int?) {
        self.id = id
        self.name = name
        self.sortName = sortName
        self.index = index
        self.releaseDate = releaseDate
        self.artists = artists
        self.favorite = favorite
        self.downloadId = downloadId
        
        self.album = nil
    }
}
