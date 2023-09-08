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
    
    let index: Index
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
    struct Index: Comparable {
        let index: Int
        let disk: Int
        
        static func < (lhs: SongItem.Index, rhs: SongItem.Index) -> Bool {
            if lhs.disk == rhs.disk {
                return lhs.index < rhs.index
            } else {
                return lhs.disk < rhs.disk
            }
        }
    }
    
    typealias Lyrics = [Double: String?]
}
