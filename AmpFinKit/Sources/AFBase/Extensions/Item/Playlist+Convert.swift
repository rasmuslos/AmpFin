//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.01.24.
//

import Foundation

extension Playlist {
    static func convertFromJellyfin(_ item: JellyfinClient.JellyfinPlaylist) -> Playlist {
        Playlist(
            id: item.Id,
            name: item.Name,
            cover: Cover.convertFromJellyfin(imageTags: item.ImageTags, id: item.Id),
            favorite: item.UserData.IsFavorite,
            duration: Double(item.RunTimeTicks ?? 0 / 10_000_000),
            trackCount: item.ChildCount ?? 0)
    }
}
