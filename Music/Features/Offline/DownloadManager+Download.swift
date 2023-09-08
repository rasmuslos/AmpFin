//
//  DownloadManager+Download.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension DownloadManager {
    func downloadAlbum(_ album: Album) async throws {
        let tracks = try await JellyfinClient.shared.getAlbumTracks(id: album.id)
        
        tracks.forEach { _ in
            
        }
    }
    
    func createItemDownloadTask() -> Int {
        return 0
    }
}
