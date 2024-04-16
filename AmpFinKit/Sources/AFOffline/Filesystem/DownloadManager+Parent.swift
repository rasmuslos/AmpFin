//
//  DownloadManager+Download.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import AFBase

extension DownloadManager {
    func downloadCover(parentId: String, cover: Item.Cover) async throws {
        let request = URLRequest(url: cover.url)
        
        let (location, _) = try await URLSession.shared.download(for: request)
        var destination = getCoverUrl(parentId: parentId)
        try? destination.setResourceValues({
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            
            return values
        }())
        
        try FileManager.default.moveItem(at: location, to: destination)
    }
    
    func isCoverDownloaded(parentId: String) -> Bool {
        FileManager.default.fileExists(atPath: getCoverUrl(parentId: parentId).absoluteString)
    }
    
    func deleteCover(parentId: String) throws {
        try FileManager.default.removeItem(at: getCoverUrl(parentId: parentId))
    }
    
    func getCoverUrl(parentId: String) -> URL {
        documentsURL.appending(path: "covers").appending(path: "\(parentId).png")
    }
}
