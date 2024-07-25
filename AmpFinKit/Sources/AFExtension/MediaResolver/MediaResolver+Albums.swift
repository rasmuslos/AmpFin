//
//  MediaResolver+Albums.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 26.04.24.
//

import Foundation
import AFFoundation
import AFNetwork
#if canImport(AFOffline)
import AFOffline
#endif

@available(macOS, unavailable)
public extension MediaResolver {
    func search(albumName name: String?, artistName artist: String?, runOffline: Bool) async throws -> [Album] {
        guard let name = name else { throw ResolveError.missing }
        
        var result = [Album]()
        
        #if canImport(AFOffline)
        if let offlineAlbums = try? OfflineManager.shared.albums(search: name) {
            result += offlineAlbums
        }
        #endif
        
        if !runOffline, let fetchedAlbums = try? await JellyfinClient.shared.albums(limit: 0, startIndex: 0, sortOrder: .lastPlayed, ascending: false, search: name).0 {
            result += fetchedAlbums.filter { !result.contains($0) }
        }
        
        result = result.filter {
            if let artist = artist {
                if !$0.artists.reduce(false, { $0 || $1.name.localizedStandardContains(artist) }) {
                    return false
                }
            }
            
            return true
        }
        
        guard !result.isEmpty else {
            throw ResolveError.empty
        }
        
        return result
    }
    
    func tracks(albumId identifier: String) async throws -> [Track] {
        #if canImport(AFOffline)
        if let tracks = try? OfflineManager.shared.tracks(albumId: identifier) {
            return tracks
        }
        #endif
        
        return try await JellyfinClient.shared.tracks(albumId: identifier)
    }
}
