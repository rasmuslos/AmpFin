//
//  AlbumItem.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

struct AlbumItem: Item {
    let id: String
    let name: String
    let sortName: String?
    
    let releaseDate: Date?
    let artists: [ItemArtist]
    
    var cover: ItemCover?
    var downloaded: Bool
    
    var favorite: Bool
    let playCount: Int
}
