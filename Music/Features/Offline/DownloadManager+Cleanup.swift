//
//  DownloadManager+Cleanup.swift
//  Music
//
//  Created by Rasmus Krämer on 27.09.23.
//

import Foundation

extension DownloadManager {
    func cleanupDirectory() throws {
        let contents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
        try contents.forEach {
            try FileManager.default.removeItem(at: $0)
        }
        
        createDirectories()
    }
}
