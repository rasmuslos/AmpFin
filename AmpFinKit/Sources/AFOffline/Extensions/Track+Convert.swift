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
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.coverURL(parentId: from.album.albumIdentifier)),
            favorite: from.favorite,
            album: ReducedAlbum(
                id: from.album.albumIdentifier,
                name: from.album.albumName,
                artists: from.album.albumArtists.map { .init(id: $0.artistIdentifier, name: $0.artistName) }),
            artists: from.artists.map { .init(id: $0.artistIdentifier, name: $0.artistName) },
            lufs: nil,
            index: Index(index: 0, disk: 0),
            runtime: from.runtime,
            playCount: -1,
            releaseDate: from.released)
    }
    
    convenience init(_ from: OfflineTrack, parent: OfflineParent) {
        self.init(
            id: from.id,
            name: from.name,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.coverURL(parentId: from.album.albumIdentifier)),
            favorite: from.favorite,
            album: ReducedAlbum(
                id: from.album.albumIdentifier,
                name: from.album.albumName,
                artists: from.album.albumArtists.map { .init(id: $0.artistIdentifier, name: $0.artistName) }),
            artists: from.artists.map { .init(id: $0.artistIdentifier, name: $0.artistName) },
            lufs: nil,
            index: Track.Index(index: (parent.childrenIdentifiers.firstIndex(of: from.id) ?? -1) + 1, disk: 0),
            runtime: from.runtime,
            playCount: -1,
            releaseDate: from.released)
    }
}
