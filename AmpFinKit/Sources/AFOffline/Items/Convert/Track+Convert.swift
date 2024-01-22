//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFBase

extension Track {
    static func convertFromOffline(_ offline: OfflineTrack) -> Track {
        return Track(
            id: offline.id,
            name: offline.name,
            cover: Item.Cover(type: .local, url: DownloadManager.shared.getCoverUrl(parentId: offline.album.id)),
            favorite: offline.favorite,
            album: ReducedAlbum(
                id: offline.album.id,
                name: offline.album.name,
                artists: offline.album.artists),
            artists: offline.artists,
            lufs: nil,
            index: Index(index: 0, disk: 0),
            runtime: offline.runtime,
            playCount: -1,
            releaseDate: offline.releaseDate)
    }
    
    static func convertFromOffline(_ offline: OfflineTrack, parent: OfflineParent) -> Track {
        return Track(
            id: offline.id,
            name: offline.name,
            cover: Item.Cover(type: .local, url: DownloadManager.shared.getCoverUrl(parentId: offline.album.id)),
            favorite: offline.favorite,
            album: ReducedAlbum(
                id: offline.album.id,
                name: offline.album.name,
                artists: offline.album.artists),
            artists: offline.artists,
            lufs: nil,
            index: Track.Index(index: (parent.childrenIds.firstIndex(of: offline.id) ?? -1) + 1, disk: 0),
            runtime: offline.runtime,
            playCount: -1,
            releaseDate: offline.releaseDate)
    }
}
