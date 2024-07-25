//
//  MediaResolver+Artists.swift
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
    func search(artistName name: String?, runOffline: Bool) async throws -> [Artist] {
        guard let name = name else { throw ResolveError.missing }
        
        guard !runOffline else {
            throw ResolveError.missing
        }
        
        let result = try await JellyfinClient.shared.artists(search: name)
        
        guard !result.isEmpty else {
            throw ResolveError.empty
        }
        
        return result
    }
    
    func tracks(artistId identifier: String) async throws -> [Track] {
        #if canImport(AFOffline)
        if let tracks = try? await OfflineManager.shared.tracks(artistId: identifier) {
            return tracks.shuffled()
        }
        #endif
        
        return try await JellyfinClient.shared.tracks(artistId: identifier, sortOrder: .random, ascending: true)
    }
}
