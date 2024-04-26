//
//  MediaResolver+Playlists.swift
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
    func search(playlistName: String?) async throws -> [Playlist] {
        guard let playlistName = playlistName else { throw ResolveError.missing }
        
        var result = [Playlist]()
        
        #if canImport(AFOffline)
        if let offlinePlaylists = try? await OfflineManager.shared.getPlaylists(query: playlistName) {
            result += offlinePlaylists
        }
        #endif
        
        if !UserDefaults.standard.bool(forKey: "siriOfflineMode"), let fetchedPlaylists = try? await JellyfinClient.shared.getPlaylists(query: playlistName) {
            result += fetchedPlaylists.filter { !result.contains($0) }
        }
        
        guard !result.isEmpty else {
            throw ResolveError.empty
        }
        
        return result
    }
    
    func resolve(playlistId: String) async throws -> [Track] {
        #if canImport(AFOffline)
        if let tracks = try? await OfflineManager.shared.getTracks(playlistId: playlistId) {
            return tracks
        }
        #endif
        
        return try await JellyfinClient.shared.getTracks(playlistId: playlistId)
    }
}
