//
//  File.swift
//
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftData
import AFFoundation

// MARK: Internal (Helper)

internal extension OfflineManager {
    func offlineTracks(parent: OfflineParent, context: ModelContext) throws -> [OfflineTrack] {
        var tracks = try parent.childrenIdentifiers.map { try offlineTrack(trackId: $0, context: context) }
        
        tracks.sort {
            let lhs = parent.childrenIdentifiers.firstIndex(of: $0.id)!
            let rhs = parent.childrenIdentifiers.firstIndex(of: $1.id)!
            
            return lhs < rhs
        }
        
        return tracks
    }
    
    func parentIds(childId: String, context: ModelContext) throws -> [String] {
        var parents = [OfflineParent]()
        
        parents += try offlineAlbums(context: context)
        parents += try offlinePlaylists(context: context)
        
        return parents.filter { $0.childrenIdentifiers.contains(childId) }.map { $0.id }
    }
    
    func downloadInProgress(parent: OfflineParent, context: ModelContext) throws -> Bool {
        try offlineTracks(parent: parent, context: context).reduce(false) { $1.downloadId == nil ? $0 : true }
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
