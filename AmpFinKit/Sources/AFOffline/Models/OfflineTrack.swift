//
//  OfflineTrack.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFBase

@Model
class OfflineTrack {
    @Attribute(.unique) let id: String
    let name: String
    
    let releaseDate: Date?
    
    let album: Track.ReducedAlbum
    let artists: [Item.ReducedArtist]
    
    var favorite: Bool
    var runtime: Double
    
    var downloadId: Int?
    
    init(id: String, name: String, releaseDate: Date?, album: Track.ReducedAlbum, artists: [Item.ReducedArtist], favorite: Bool, runtime: Double, downloadId: Int? = nil) {
        self.id = id
        self.name = name
        self.album = album
        self.releaseDate = releaseDate
        self.artists = artists
        self.favorite = favorite
        self.downloadId = downloadId
        self.runtime = runtime
    }
}
