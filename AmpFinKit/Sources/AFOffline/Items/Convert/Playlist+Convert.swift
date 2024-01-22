//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import AFBase

extension Playlist {
    static func convertFromOffline(_ playlist: OfflinePlaylist) -> Playlist {
        Playlist(
            id: playlist.id,
            name: playlist.name,
            cover: Item.Cover(type: .local, url: DownloadManager.shared.getCoverUrl(parentId: playlist.id)),
            favorite: playlist.favorite,
            duration: playlist.duration,
            trackCount: playlist.trackCount)
    }
}
