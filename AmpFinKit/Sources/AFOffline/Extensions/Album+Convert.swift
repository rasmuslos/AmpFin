//
//  File 2.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFFoundation

internal extension Album {
    convenience init(_ from: OfflineAlbum) {
        self.init(
            id: from.id,
            name: from.name,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.coverURL(parentId: from.id)),
            favorite: from.favorite,
            overview: from.overview,
            genres: from.genres,
            releaseDate: from.released,
            artists: from.artists.map { .init(id: $0.artistIdentifier, name: $0.artistName) },
            playCount: -1,
            lastPlayed: nil)
    }
}
