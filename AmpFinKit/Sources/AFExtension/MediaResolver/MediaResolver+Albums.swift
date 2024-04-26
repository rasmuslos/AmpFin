//
//  MediaResolver+Albums.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 26.04.24.
//

import Foundation
import AFBase
#if canImport(AFOffline)
import AFOffline
#endif

public extension MediaResolver {
    func search(albumName: String?, artistName: String?) async throws -> [Album] {
        guard let albumName = albumName else { throw ResolveError.missing }
        
        var result = [Album]()
        
        #if canImport(AFOffline)
        if let offlineAlbums = try? await OfflineManager.shared.getAlbums(query: albumName) {
            result += offlineAlbums
        }
        #endif
        
        if !UserDefaults.standard.bool(forKey: "siriOfflineMode"), let fetchedAlbums = try? await JellyfinClient.shared.getAlbums(query: albumName) {
            result += fetchedAlbums.filter { !result.contains($0) }
        }
        
        result = result.filter {
            if let artistName = artistName {
                if !$0.artists.reduce(false, { $0 || $1.name.localizedStandardContains(artistName) }) {
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
    
    func resolve(albumId: String) async throws -> [Track] {
        #if canImport(AFOffline)
        if let tracks = try? await OfflineManager.shared.getTracks(albumId: albumId) {
            return tracks
        }
        #endif
        
        return try await JellyfinClient.shared.getTracks(albumId: albumId)
    }
}
