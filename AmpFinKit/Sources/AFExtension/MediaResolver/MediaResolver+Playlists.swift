//
//  MediaResolver+Playlists.swift
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
    func search(playlistName name: String?, runOffline: Bool) async throws -> [Playlist] {
        guard let name = name else { throw ResolveError.missing }
        
        var result = [Playlist]()
        
        #if canImport(AFOffline)
        if let offlinePlaylists = try? await OfflineManager.shared.playlists().filter({ $0.name.localizedStandardContains(name) }) {
            result += offlinePlaylists
        }
        #endif
        
        if !runOffline, let fetchedPlaylists = try? await JellyfinClient.shared.playlists(limit: 0, sortOrder: .lastPlayed, ascending: false, search: name) {
            result += fetchedPlaylists.filter { !result.contains($0) }
        }
        
        guard !result.isEmpty else {
            throw ResolveError.empty
        }
        
        return result
    }
    
    func tracks(playlistId identifier: String) async throws -> [Track] {
        #if canImport(AFOffline)
        if let tracks = try? await OfflineManager.shared.tracks(playlistId: identifier) {
            return tracks
        }
        #endif
        
        return try await JellyfinClient.shared.tracks(playlistId: identifier)
    }
}
