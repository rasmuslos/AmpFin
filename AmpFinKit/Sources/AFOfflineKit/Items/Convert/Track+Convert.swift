//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBaseKit

extension Track {
    static func convertFromOffline(_ offline: OfflineTrack) -> Track {
        return Track(
            id: offline.id,
            name: offline.name,
            cover: Item.Cover(type: .local, url: DownloadManager.shared.getAlbumCoverUrl(albumId: offline.album.id)),
            favorite: offline.favorite,
            album: ReducedAlbum(
                id: offline.album.id,
                name: offline.album.name,
                artists: offline.album.artists),
            artists: offline.artists,
            lufs: nil,
            index: offline.index,
            playCount: -1,
            releaseDate: offline.releaseDate)
    }
}
