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
        // SwiftData sucks complete ass
        return try getOfflineTracks().filter { parent.childrenIds.contains($0.id) }
    }
    
    @MainActor
    func isDownloadInProgress(parent: OfflineParent) throws -> Bool {
        let tracks = try getOfflineTracks(parent: parent)
        return tracks.reduce(false) { $1.downloadId == nil ? $0 : true }
    }
    
    @MainActor
    func isTrackInUse(trackId: String) throws -> Bool {
        let albumDependencies = try getOfflineAlbums().reduce([String](), {
            var result = $0
            result.append(contentsOf: $1.childrenIds)
            
            return result
        })
        
        if albumDependencies.contains(trackId) {
            return true
        }
        
        let playlistDependencies = try getOfflinePlaylists().reduce([String](), {
            var result = $0
            result.append(contentsOf: $1.childrenIds)
            
            return result
        })
        
        return playlistDependencies.contains(trackId)
    }
    
    func download(parent: OfflineParent, tracks: [Track]) {
        for track in tracks {
            Task.detached {
                await download(track: track)
            }
        }
    }
    
    func delete(parent: OfflineParent) throws {
        for trackId in parent.childrenIds {
            Task.detached {
                if try await !isTrackInUse(trackId: trackId), let track = try? await getOfflineTrack(trackId: trackId) {
                    await delete(track: track)
                }
            }
        }
    }
}
