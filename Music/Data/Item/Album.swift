//
//  Album.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

class Album: Item {
    let overview: String?
    let genres: [String]
    
    let releaseDate: Date?
    let artists: [ReducedArtist]
    
    let playCount: Int
    
    init(id: String, name: String, sortName: String?, cover: Cover? = nil, favorite: Bool, overview: String?, genres: [String], releaseDate: Date?, artists: [ReducedArtist], playCount: Int) {
        self.overview = overview
        self.genres = genres
        self.releaseDate = releaseDate
        self.artists = artists
        self.playCount = playCount
        
        super.init(id: id, name: name, sortName: sortName, cover: cover, favorite: favorite)
    }
    
    override func checkOfflineStatus() {
        Task.detached { [self] in
            self.offline = await OfflineManager.shared.getAlbumOfflineStatus(albumId: id)
        }
    }
}
