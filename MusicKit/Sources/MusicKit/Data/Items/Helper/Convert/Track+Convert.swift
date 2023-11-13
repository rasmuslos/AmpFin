//
//  Track+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension Track {
    static func convertFromJellyfin(_ item: JellyfinClient.JellyfinTrackItem, fallbackIndex: Int = 0) -> Track {
        var cover: Item.Cover?
        
        // TODO: Remove this, too
        if item.ImageTags.Primary != nil {
            cover = Cover.convertFromJellyfin(imageTags: item.ImageTags, id: item.Id)
        } else if let imageTag = item.AlbumPrimaryImageTag {
            cover = Cover.convertFromJellyfin(imageTags: JellyfinClient.ImageTags.init(Primary: imageTag), id: item.AlbumId)
        }
        
        return Track(
            id: item.Id,
            name: item.Name,
            sortName: item.Name,
            cover: cover,
            favorite: item.UserData.IsFavorite,
            album: ReducedAlbum(
                id: item.AlbumId,
                name: item.Album,
                artists: item.AlbumArtists.map {
                    ReducedArtist(
                        id: $0.Id,
                        name: $0.Name)
                }),
            artists: item.ArtistItems.map {
                ReducedArtist(id: $0.Id, name: $0.Name)
            },
            lufs: item.LUFS,
            index: Index(index: item.IndexNumber ?? fallbackIndex, disk: item.ParentIndexNumber ?? 1),
            playCount: item.UserData.PlayCount,
            releaseDate: Date.parseDate(item.PremiereDate))
    }
    
    static func convertFromOffline(_ offline: OfflineTrack) -> Track {
        return Track(
            id: offline.id,
            name: offline.name,
            sortName: nil,
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
    
    // TODO: Remove when 10.9 gets released, as it is not required in this version
    fileprivate struct TrackImage {
        let id: String
        let tag: String
    }
}
