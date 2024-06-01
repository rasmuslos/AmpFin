//
//  MediaResolver+Tracks.swift
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
    func search(trackName name: String?, albumName album: String?, artistName artist: String?) async throws -> [Track] {
        guard let name = name else { throw ResolveError.missing }
        
        var result = [Track]()
        
        #if canImport(AFOffline)
        if let offlineTracks = try? await OfflineManager.shared.tracks().filter({ $0.name.localizedStandardContains(name) || $0.artists.map { $0.name }.reduce(false, { $0 || $1.localizedStandardContains(name) })}) {
            result += offlineTracks
        }
        #endif
        
        if !JellyfinClient.shared.siriOfflineMode, let fetchedTracks = try? await JellyfinClient.shared.tracks(limit: 0, startIndex: 0, sortOrder: .lastPlayed, ascending: false, search: name).0 {
            result += fetchedTracks.filter { !result.contains($0) }
        }
        
        result = result.filter {
            if let album = album, let name = $0.album.name, !name.localizedStandardContains(album) {
                return false
            }
            
            if let artist = artist, !$0.artists.reduce(false, { $0 || $1.name.localizedStandardContains(artist) }) {
                return false
            }
            
            return true
        }
        
        guard !result.isEmpty else {
            throw ResolveError.empty
        }
        
        return result
    }
    
    func track(id trackId: String) async throws -> Track {
        #if canImport(AFOffline)
        if let track = try? await OfflineManager.shared.track(identifier: trackId) {
            return track
        }
        #endif
        
        return try await JellyfinClient.shared.track(identifier: trackId)
    }
}
