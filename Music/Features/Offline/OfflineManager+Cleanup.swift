//
//  DownloadManager+Cleanup.swift
//  Music
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

// MARK: Remove tracks

extension OfflineManager {
    func removeUnfinishedDownloads() async throws {
        let tracks = try await OfflineManager.shared.getUnfinishedDownloads()
        var albums = Set<OfflineAlbum>()
        
        tracks.forEach {
            albums.insert($0.album)
        }
        
        for album in albums {
            try await OfflineManager.shared.deleteOfflineAlbum(album)
        }
    }
}
