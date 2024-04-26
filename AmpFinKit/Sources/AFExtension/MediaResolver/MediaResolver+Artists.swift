//
//  MediaResolver+Artists.swift
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
    func search(artistName: String?) async throws -> [Artist] {
        guard let artistName = artistName else { throw ResolveError.missing }
        
        let result = try await JellyfinClient.shared.getArtists(query: artistName)
        
        guard !result.isEmpty else {
            throw ResolveError.empty
        }
        
        return result
    }
    
    func resolve(artistId: String) async throws -> [Track] {
        #if canImport(AFOffline)
        if let tracks = try? await OfflineManager.shared.getTracks(artistId: artistId) {
            return tracks.shuffled()
        }
        #endif
        
        return try await JellyfinClient.shared.getTracks(artistId: artistId).shuffled()
    }
}
