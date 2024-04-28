//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 04.01.24.
//

import Foundation
import AFBase

#if canImport(AFOffline)
import AFOffline
#endif

extension Playlist {
    public func add(trackIds: [String]) async throws {
        try await JellyfinClient.shared.add(trackIds: trackIds, playlistId: id)
        
        #if canImport(AFOffline)
        if await OfflineManager.shared.isPlaylistDownloaded(playlistId: id) {
            try await OfflineManager.shared.download(playlist: self)
        }
        #endif
        
        // might not be true but who cares
        trackCount += 1
    }
}
