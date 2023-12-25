//
//  AlbumItem+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AFBaseKit

extension Album {
    /// Convert an item received from the Jellyfin server into an album type
    static func convertFromJellyfin(_ item: JellyfinClient.JellyfinAlbum) -> Album {
        Album(
            id: item.Id,
            name: item.Name,
            cover: Cover.convertFromJellyfin(imageTags: item.ImageTags, id: item.Id),
            favorite: item.UserData.IsFavorite,
            overview: item.Overview,
            genres: item.Genres ?? [],
            releaseDate: Date.parseDate(item.PremiereDate),
            artists: item.AlbumArtists.map { ReducedArtist(id: $0.Id, name: $0.Name) },
            playCount: item.UserData.PlayCount)
    }
}
