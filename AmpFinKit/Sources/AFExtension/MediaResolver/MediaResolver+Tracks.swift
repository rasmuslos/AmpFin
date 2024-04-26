//
//  MediaResolver+Tracks.swift
//  Siri Extension
//
//  Created by Rasmus Krämer on 26.04.24.
//

import Foundation
import AFBase
import AFOffline

public extension MediaResolver {
    func search(trackName: String?, albumName: String?, artistName: String?) async throws -> [Track] {
        guard let trackName = trackName else { throw ResolveError.missing }
        
        var result = [Track]()
        
        #if canImport(AFOffline)
        if let offlineTracks = try? await OfflineManager.shared.getTracks(query: trackName) {
            result += offlineTracks
        }
        #endif
        
        if !UserDefaults.standard.bool(forKey: "siriOfflineMode"), let fetchedTracks = try? await JellyfinClient.shared.getTracks(query: trackName) {
            result += fetchedTracks.filter { !result.contains($0) }
        }
        
        result = result.filter {
            if let albumName = albumName, let name = $0.album.name {
                if !name.localizedStandardContains(albumName) {
                    return false
                }
            }
            
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
    
    func resolve(trackId: String) async throws -> Track {
        #if canImport(AFOffline)
        if let track = try? await OfflineManager.shared.getTrack(id: trackId) {
            return track
        }
        #endif
        
        return try await JellyfinClient.shared.getTrack(id: trackId)
    }
}
