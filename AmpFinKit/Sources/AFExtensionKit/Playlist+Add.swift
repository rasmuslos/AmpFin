//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 04.01.24.
//

import Foundation
import AFBaseKit

#if canImport(AFOfflineKit)
import AFOfflineKit
#endif

extension Playlist {
    public func add(trackIds: [String]) async throws {
        try await JellyfinClient.shared.add(trackIds: trackIds, playlistId: id)
        
        #if canImport(AFOfflineKit)
        if (try? await OfflineManager.shared.getPlaylist(playlistId: id)) != nil {
            try await OfflineManager.shared.download(playlist: self)
        }
        #endif
        
        // might not be true but who cares
        trackCount += 1
    }
}
