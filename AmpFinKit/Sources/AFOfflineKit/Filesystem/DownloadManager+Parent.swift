//
//  DownloadManager+Download.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import AFBaseKit

extension DownloadManager {
    func downloadCover(parentId: String, cover: Item.Cover) async throws {
        let request = URLRequest(url: cover.url)
        
        let (location, _) = try await URLSession.shared.download(for: request)
        try FileManager.default.moveItem(at: location, to: getCoverUrl(parentId: parentId))
    }
    
    func deleteCover(parentId: String) throws {
        try FileManager.default.removeItem(at: getCoverUrl(parentId: parentId))
    }
    
    func getCoverUrl(parentId: String) -> URL {
        documentsURL.appending(path: "covers").appending(path: "\(parentId).png")
    }
}
