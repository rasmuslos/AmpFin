//
//  DownloadManager+Download.swift
//  Music
//
//  Created by Rasmus Krämer on 08.09.23.
//

import Foundation
import AFFoundation

extension DownloadManager {
    func coverDownloaded(parentId: String) -> Bool {
        FileManager.default.fileExists(atPath: coverURL(parentId: parentId).absoluteString)
    }
    
    func downloadCover(parentId: String, cover: Cover) async throws {
        let request = URLRequest(url: cover.url)
        
        let (location, _) = try await URLSession.shared.download(for: request)
        var destination = coverURL(parentId: parentId)
        var values = URLResourceValues()
        
        values.isExcludedFromBackup = true
        try? destination.setResourceValues(values)
        
        try FileManager.default.moveItem(at: location, to: destination)
    }
    
    func deleteCover(parentId: String) throws {
        try FileManager.default.removeItem(at: coverURL(parentId: parentId))
    }
    
    func coverURL(parentId: String) -> URL {
        covers.appending(path: "\(parentId).png")
    }
}
