//
//  DownloadManager+Cleanup.swift
//  Music
//
//  Created by Rasmus Krämer on 27.09.23.
//

import Foundation

public extension DownloadManager {
    func cleanupDirectory() throws {
        let contents = try FileManager.default.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil)
        
        for entity in contents {
            try FileManager.default.removeItem(at: entity)
        }
        
        createDirectories()
    }
}
