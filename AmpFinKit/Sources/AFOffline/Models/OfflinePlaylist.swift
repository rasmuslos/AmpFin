//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftData

@Model
final internal class OfflinePlaylistV2: OfflineParent {
    @Attribute(.unique)
    let id: String
    let name: String
    
    var favorite: Bool
    var duration: Double
    
    var childrenIdentifiers: [String]
    
    var lastPlayed: Date?
    
    init(id: String, name: String, favorite: Bool, duration: Double, childrenIdentifiers: [String]) {
        self.id = id
        self.name = name
        self.favorite = favorite
        self.duration = duration
        self.childrenIdentifiers = childrenIdentifiers
    }
}

internal typealias OfflinePlaylist = OfflinePlaylistV2
