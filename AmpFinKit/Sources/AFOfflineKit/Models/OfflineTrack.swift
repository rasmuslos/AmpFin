//
//  OfflineTrack.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import SwiftData
import AFBaseKit

@Model
class OfflineTrack {
    @Attribute(.unique) let id: String
    let name: String
    
    let index: Track.Index
    let releaseDate: Date?
    
    @Relationship
    var album: OfflineAlbum!
    let artists: [Item.ReducedArtist]
    
    var favorite: Bool
    var runtime: Double
    
    var downloadId: Int?
    
    init(id: String, name: String, index: Track.Index, releaseDate: Date?, artists: [Item.ReducedArtist], favorite: Bool, runtime: Double, downloadId: Int? = nil) {
        self.id = id
        self.name = name
        self.index = index
        self.releaseDate = releaseDate
        self.artists = artists
        self.favorite = favorite
        self.downloadId = downloadId
        self.runtime = runtime
        
        self.album = nil
    }
}
