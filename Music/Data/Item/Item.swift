//
//  Item.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

protocol Item: Identifiable {
    var id: String { get }
    var name: String { get }
    var cover: ItemCover? { get set }
    var downloaded: Bool { get set }
    var favorite: Bool { get set }
}

struct ItemCover {
    let type: ItemCoverType
    let url: URL
    
    enum ItemCoverType {
    case local
    case remote
    }
}
struct ItemArtist {
    let id: String
    let name: String
}

enum ItemType {
    case song
    case album
    case artist
    case genre
}
