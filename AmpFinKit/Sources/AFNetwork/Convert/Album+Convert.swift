//
//  AlbumItem+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 06.09.23.
//

import Foundation
import AFFoundation

internal extension Album {
    convenience init(_ from: JellyfinItem) {
        var lastPlayed: Date?
        
        if let lastPlayedDate = from.UserData?.LastPlayedDate {
            lastPlayed = Date(lastPlayedDate)
        }
        
        self.init(
            id: from.Id,
            name: from.Name!,
            cover: .init(imageTags: from.ImageTags!, id: from.Id),
            favorite: from.UserData!.IsFavorite,
            overview: from.Overview,
            genres: from.Genres ?? [],
            releaseDate: Date(from.PremiereDate),
            artists: from.AlbumArtists?.map { ReducedArtist(id: $0.Id, name: $0.Name) } ?? [],
            playCount: from.UserData!.PlayCount,
            lastPlayed: lastPlayed)
    }
}
