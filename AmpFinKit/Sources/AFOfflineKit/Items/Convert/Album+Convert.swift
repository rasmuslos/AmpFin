//
//  File 2.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBaseKit

extension Album {
    static func convertFromOffline(_ offline: OfflineAlbum) -> Album {
        Album(
            id: offline.id,
            name: offline.name,
            cover: Item.Cover(type: .local, url: DownloadManager.shared.getCoverUrl(albumId: offline.id)),
            favorite: offline.favorite,
            overview: offline.overview,
            genres: offline.genres,
            releaseDate: offline.releaseDate,
            artists: offline.artists,
            playCount: -1)
    }
}
