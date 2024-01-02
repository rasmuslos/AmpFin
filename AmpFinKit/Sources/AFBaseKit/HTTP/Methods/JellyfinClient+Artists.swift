//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 24.12.23.
//

import Foundation

public extension JellyfinClient {
    /// Get all artists from all libraries
    func getArtists(albumOnly: Bool) async throws -> [Artist] {
        let response = try await request(ClientRequest<ArtistItemsResponse>(path: albumOnly ? "Artists/AlbumArtists" : "Artists", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: ItemSortOrder.name.rawValue),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
        ], userId: true))
        
        return response.Items.map(Artist.convertFromJellyfin)
    }
    
    /// Get an artist by its their ID
    func getArtist(artistId: String) async throws -> Artist {
        if let artist = try await request(ClientRequest<JellyfinFullArtist?>(path: "Items/\(artistId)", method: "GET", userPrefix: true)) {
            return Artist.convertFromJellyfin(artist)
        }
        
        throw JellyfinClientError.invalidResponse
    }
}
