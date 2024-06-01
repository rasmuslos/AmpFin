//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 21.05.24.
//

import Foundation
import AFFoundation

internal extension ItemSortOrder {
    var value: String {
        switch self {
            case .name:
                "Name"
            case .album:
                "Album,SortName"
            case .albumArtist:
                "AlbumArtist,Album,SortName"
            case .artist:
                "Artist,Album,SortName"
            case .added:
                "DateCreated,SortName"
            case .plays:
                "PlayCount,SortName"
            case .lastPlayed:
                "DatePlayed,SortName"
            case .released:
                "ProductionYear,PremiereDate,SortName"
            case .runtime:
                "Runtime,AlbumArtist,Album,SortName"
            case .random:
                "Random"
        }
    }
}
