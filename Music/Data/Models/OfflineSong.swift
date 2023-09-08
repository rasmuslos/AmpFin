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
    let cover: Item.Cover
    
    let index: Track.Index
    let releaseDate: Date?
    
    let album: OfflineAlbum
    let artists: [Item.ReducedArtist]
    
    var favorite: Bool
    var downloadId: Int?
    
    init(id: String, name: String, cover: Item.Cover, index: Track.Index, releaseDate: Date?, album: OfflineAlbum, artists: [Item.ReducedArtist], favorite: Bool, downloadId: Int?) {
        self.id = id
        self.name = name
        self.cover = cover
        self.index = index
        self.releaseDate = releaseDate
        self.album = album
        self.artists = artists
        self.favorite = favorite
        self.downloadId = downloadId
    }
}

// MARK: Helper

extension OfflineTrack {
    func isDownloaded() -> Bool {
        downloadId == nil
    }
}
