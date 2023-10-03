//
//  DownloadManager+Download.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation

extension DownloadManager {
    func downloadAlbumCover(albumId: String, cover: Item.Cover) async throws {
        let request = URLRequest(url: cover.url)
        
        let (location, _) = try await URLSession.shared.download(for: request)
        try FileManager.default.moveItem(at: location, to: getAlbumCoverUrl(albumId: albumId))
    }
    
    func deleteAlbumCover(albumId: String) throws {
        try FileManager.default.removeItem(at: getAlbumCoverUrl(albumId: albumId))
    }
    
    func getAlbumCoverUrl(albumId: String) -> URL {
        documentsURL.appending(path: "covers").appending(path: "\(albumId).png")
    }
}
