//
//  Track+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension Track {
    static func convertFromJellyfin(_ item: JellyfinClient.JellyfinTrackItem, fallbackIndex: Int = 0) -> Track {
        let album = ReducedAlbum(
            id: item.AlbumId,
            name: item.Album,
            artists: item.AlbumArtists.map {
                ReducedArtist(
                    id: $0.Id,
                    name: $0.Name)
            })
        
        return Track(
            id: item.Id,
            name: item.Name,
            sortName: item.Name,
            cover: Cover.convertFromJellyfin(
                imageTags: item.ImageTags,
                id: item.Id),
            favorite: item.UserData.IsFavorite,
            album: album,
            artists: item.ArtistItems.map {
                ReducedArtist(id: $0.Id, name: $0.Name)
            },
            lufs: item.LUFS,
            index: Index(index: item.IndexNumber ?? fallbackIndex, disk: item.ParentIndexNumber ?? 1),
            playCount: item.UserData.PlayCount,
            releaseDate: Date.parseDate(item.PremiereDate))
    }
}
