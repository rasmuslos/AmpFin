//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation
import AFFoundation

internal extension Track {
    convenience init(_ from: OfflineTrack) {
        self.init(
            id: from.id,
            name: from.name,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.coverURL(parentId: from.album.id)),
            favorite: from.favorite,
            album: ReducedAlbum(
                id: from.album.id,
                name: from.album.name,
                artists: from.album.artists),
            artists: from.artists,
            lufs: nil,
            index: Index(index: 0, disk: 0),
            runtime: from.runtime,
            playCount: -1,
            releaseDate: from.releaseDate)
    }
    
    convenience init(_ from: OfflineTrack, parent: OfflineParent) {
        self.init(
            id: from.id,
            name: from.name,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.coverURL(parentId: from.album.id)),
            favorite: from.favorite,
            album: ReducedAlbum(
                id: from.album.id,
                name: from.album.name,
                artists: from.album.artists),
            artists: from.artists,
            lufs: nil,
            index: Track.Index(index: (parent.childrenIds.firstIndex(of: from.id) ?? -1) + 1, disk: 0),
            runtime: from.runtime,
            playCount: -1,
            releaseDate: from.releaseDate)
    }
}
