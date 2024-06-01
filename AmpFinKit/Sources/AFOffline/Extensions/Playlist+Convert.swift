//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import AFFoundation

internal extension Playlist {
    convenience init(_ from: OfflinePlaylist) {
        self.init(
            id: from.id,
            name: from.name,
            cover: Cover(type: .local, size: .normal, url: DownloadManager.shared.coverURL(parentId: from.id)),
            favorite: from.favorite,
            duration: from.duration,
            trackCount: from.trackCount)
    }
}
