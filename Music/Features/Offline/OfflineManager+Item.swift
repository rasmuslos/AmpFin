//
//  OfflineManager+Item.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension OfflineManager {
    func createOfflineTrack(_ track: Track, album: OfflineAlbum, taskId: Int) {
        let offlineItem = OfflineTrack(
            id: track.id,
            name: track.name,
            cover: Item.Cover(type: .local, url: URL(string: "https://balls.com")!), // TODO,
            index: track.index,
            releaseDate: track.releaseDate,
            album: album,
            artists: track.artists,
            favorite: track.favorite,
            downloadId: taskId)
    }
}
