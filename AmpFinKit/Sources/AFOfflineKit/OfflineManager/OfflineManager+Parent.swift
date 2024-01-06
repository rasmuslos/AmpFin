//
//  File.swift
//
//
//  Created by Rasmus Krämer on 02.01.24.
//

import Foundation
import SwiftData
import AFBaseKit

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
        return []
        
        // this does not work because
        #if false
        let albumDescriptor = FetchDescriptor<OfflineAlbum>(predicate: #Predicate {
            $0.childrenIds.contains(childId)
        })
        let albums = try PersistenceManager.shared.modelContainer.mainContext.fetch(albumDescriptor)
        
        let playlistDescriptor = FetchDescriptor<OfflinePlaylist>(predicate: #Predicate {
            $0.childrenIds.contains(childId)
        })
        let playlists = try PersistenceManager.shared.modelContainer.mainContext.fetch(playlistDescriptor)
        
        return albums.map { $0.id } + playlists.map { $0.id }
        #endif
    }
    
    @MainActor
    func isDownloadInProgress(parent: OfflineParent) throws -> Bool {
        let tracks = try getOfflineTracks(parent: parent)
        return tracks.reduce(false) { $1.downloadId == nil ? $0 : true }
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
