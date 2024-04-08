//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 25.12.23.
//

import Foundation
import Defaults

public extension JellyfinClient {
    enum ItemSortOrder: String, CaseIterable, Codable, _DefaultsSerializable {
        case name = "Name"
        case album = "Album,SortName"
        case albumArtist = "AlbumArtist,Album,SortName"
        case artist = "Artist,Album,SortName"
        case added = "DateCreated,SortName"
        case plays = "PlayCount,SortName"
        case lastPlayed = "DatePlayed,SortName"
        case released = "ProductionYear,PremiereDate,SortName"
        case runtime = "Runtime,AlbumArtist,Album,SortName"
    }
}
