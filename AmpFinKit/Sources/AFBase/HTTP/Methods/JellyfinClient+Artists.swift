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
        ]))
        
        return response.Items.map(Artist.convertFromJellyfin)
    }
    
    func getArtists(query: String) async throws -> [Artist] {
        let response = try await request(ClientRequest<ArtistItemsResponse>(path: "Artists", method: "GET", query: [
            URLQueryItem(name: "searchTerm", value: query),
            URLQueryItem(name: "Limit", value: "20"),
            URLQueryItem(name: "Recursive", value: "true"),
        ]))
        
        return response.Items.map(Artist.convertFromJellyfin)
    }
    
    /// Get an artist by its their ID
    func getArtist(artistId: String) async throws -> Artist {
        if let artist = try await request(ClientRequest<JellyfinFullArtist?>(path: "Items/\(artistId)", method: "GET")) {
            return Artist.convertFromJellyfin(artist)
        }
        
        throw JellyfinClientError.invalidResponse
    }
    
    func getTracks(artistId: String) async throws -> [Track] {
        let response = try await request(ClientRequest<TracksItemResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: "ParentIndexNumber,IndexNumber,SortName"),
            URLQueryItem(name: "SortOrder", value: "Ascending"),
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "ArtistIds", value: artistId),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
            URLQueryItem(name: "Filters", value: "IsNotFolder"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "Limit", value: "100"),
        ]))
        
        return response.Items.enumerated().compactMap { try? Track.convertFromJellyfin($1, fallbackIndex: $0) }
    }
}
