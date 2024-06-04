//
//  File.swift
//
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftData
import AFFoundation

extension OfflineManager {
    @MainActor
    func offlineTracks(parent: OfflineParent) throws -> [OfflineTrack] {
        var tracks = try parent.childrenIdentifiers.map { try offlineTrack(trackId: $0) }
        
        tracks.sort {
            let lhs = parent.childrenIdentifiers.firstIndex(of: $0.id)!
            let rhs = parent.childrenIdentifiers.firstIndex(of: $1.id)!
            
            return lhs < rhs
        }
        
        return tracks
    }
    
    @MainActor
    func parentIds(childId: String) throws -> [String] {
        var parents = [OfflineParent]()
        
        parents += try offlineAlbums()
        parents += try offlinePlaylists()
        
        return parents.filter { $0.childrenIdentifiers.contains(childId) }.map { $0.id }
    }
    
    @MainActor
    func downloadInProgress(parent: OfflineParent) throws -> Bool {
        try offlineTracks(parent: parent).reduce(false) { $1.downloadId == nil ? $0 : true }
    }
    
    func reduceToChildrenIdentifiers(parents: [OfflineParent]) -> Set<String> {
        var result = Set<String>()
        
        for parent in parents {
            for trackId in parent.childrenIdentifiers {
                result.insert(trackId)
            }
        }
        
        return result
    }
}
