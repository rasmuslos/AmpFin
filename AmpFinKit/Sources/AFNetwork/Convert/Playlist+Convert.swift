//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.01.24.
//

import Foundation
import AFFoundation

internal extension Playlist {
    convenience init(_ from: JellyfinItem) {
        var runtime: Double?
        
        if let runTimeTicks = from.RunTimeTicks {
            runtime = Double(runTimeTicks / 10_000_000)
        }
        
        self.init(
            id: from.Id,
            name: from.Name!,
            cover: .init(imageTags: from.ImageTags!, id: from.Id),
            favorite: from.UserData!.IsFavorite,
            duration: runtime ?? 0,
            trackCount: from.ChildCount ?? 0)
    }
}
