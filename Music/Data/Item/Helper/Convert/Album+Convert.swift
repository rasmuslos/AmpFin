//
//  AlbumItem+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension Album {
    static func convertFromJellyfin(_ item: JellyfinClient.JellyfinAlbum) -> Album {
        Album(
            id: item.Id,
            name: item.Name,
            sortName: item.SortName,
            cover: Cover.convertFromJellyfin(imageTags: item.ImageTags, id: item.Id),
            favorite: item.UserData.IsFavorite,
            overview: item.Overview,
            genres: item.Genres,
            releaseDate: Date.parseDate(item.PremiereDate),
            artists: item.AlbumArtists.map {
                ReducedArtist(
                    id: $0.Id,
                    name: $0.Name)
            },
            playCount: item.UserData.PlayCount)
    }
    
    static func convertFromOffline(_ offline: OfflineAlbum) -> Album {
        Album(
            id: offline.id,
            name: offline.name,
            sortName: offline.sortName,
            cover: offline.cover,
            favorite: offline.favorite,
            overview: offline.overview,
            genres: offline.genres,
            releaseDate: offline.releaseDate,
            artists: offline.artists,
            playCount: -1)
    }
}
