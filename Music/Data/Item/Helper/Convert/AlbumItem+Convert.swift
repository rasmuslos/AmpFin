//
//  AlbumItem+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation

extension AlbumItem {
    static func convertFromJellyfin(_ item: JellyfinClient.JellyfinAlbum) -> AlbumItem {
        return AlbumItem(
            id: item.Id,
            name: item.Name,
            sortName: item.SortName,
            overview: item.Overview,
            genres: item.Genres,
            releaseDate: Date.parseDate(item.PremiereDate),
            artists: item.AlbumArtists.map {
                ItemArtist(id: $0.Id, name: $0.Name)
            },
            cover: ItemCover.convertFromJellyfin(imageTags: item.ImageTags, id: item.Id),
            downloaded: false,
            favorite: item.UserData.IsFavorite,
            playCount: item.UserData.PlayCount)
    }
}
