//
//  SongItem.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

struct SongItem: Item {
    let id: String
    let name: String
    var cover: ItemCover?
    
    let index: Int
    let playCount: Int
    
    let lufs: Float?
    let releaseDate: Date?
    
    let album: Album
    let artists: [ItemArtist]
    
    var downloaded: Bool
    var favorite: Bool
    
    struct Album {
        let id: String
        let name: String
        let artists: [ItemArtist]
    }
    
    typealias Lyrics = [Double: String?]
}
