//
//  ArtistItem+Convert.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import AFFoundation

internal extension Artist {
    convenience init(_ from: JellyfinItem) {
        self.init(
            id: from.Id,
            name: from.Name!,
            cover: .init(imageTags: from.ImageTags!, id: from.Id),
            favorite: from.UserData!.IsFavorite,
            overview: from.Overview)
    }
}

