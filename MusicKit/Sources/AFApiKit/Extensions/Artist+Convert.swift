//
//  ArtistItem+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import AFBaseKit

extension Artist {
    /// Convert an item received from the Jellyfin server into an artist type
    static func convertFromJellyfin(_ item: JellyfinClient.JellyfinFullArtist) -> Artist {
        return Artist(
            id: item.Id,
            name: item.Name,
            cover: Cover.convertFromJellyfin(imageTags: item.ImageTags, id: item.Id),
            favorite: item.UserData.IsFavorite,
            overview: item.Overview)
    }
}

