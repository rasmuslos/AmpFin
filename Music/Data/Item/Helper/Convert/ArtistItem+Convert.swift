//
//  ArtistItem+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension Artist {
    static func convertFromJellyfin(_ item: JellyfinClient.JellyfinFullArtist) -> Artist {
        return Artist(
            id: item.Id,
            name: item.Name,
            sortName: item.SortName,
            cover: Cover.convertFromJellyfin(imageTags: item.ImageTags, id: item.Id),
            favorite: item.UserData.IsFavorite,
            overview: item.Overview)
    }
}

