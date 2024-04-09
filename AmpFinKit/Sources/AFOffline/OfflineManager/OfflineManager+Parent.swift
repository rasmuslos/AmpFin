//
//  File.swift
//
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftData
import AFBase

extension OfflineManager {
    @MainActor
    func getOfflineTracks(parent: OfflineParent) throws -> [OfflineTrack] {
        var tracks = try parent.childrenIds.map { try getOfflineTrack(trackId: $0) }
        
        tracks.sort {
            let lhs = parent.childrenIds.firstIndex(of: $0.id)!
            let rhs = parent.childrenIds.firstIndex(of: $1.id)!
            
            return lhs < rhs
        }
        
        return tracks
    }
    
    @MainActor
    func getParentIds(childId: String) throws -> [String] {
        // this is the best way to do this, fuck SwiftData
        var parents = [OfflineParent]()
        
        parents += try getOfflineAlbums()
        parents += try getOfflinePlaylists()
        
        return parents.filter { $0.childrenIds.contains(childId) }.map { $0.id }
    }
    
    @MainActor
    func isDownloadInProgress(parent: OfflineParent) throws -> Bool {
        let tracks = try getOfflineTracks(parent: parent)
        return tracks.reduce(false) { $1.downloadId ?? -1 < 0 ? $0 : true }
    }
    
    func reduceToChildrenIds(parents: [OfflineParent]) -> Set<String> {
        var result = Set<String>()
        
        for parent in parents {
            for trackId in parent.childrenIds {
                result.insert(trackId)
            }
        }
        
        return result
    }
}
