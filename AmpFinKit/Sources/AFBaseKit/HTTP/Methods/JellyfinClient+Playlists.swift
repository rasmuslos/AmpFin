//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 01.01.24.
//

import Foundation

public extension JellyfinClient {
    func getPlaylists(limit: Int, sortOrder: ItemSortOrder, ascending: Bool, favorite: Bool) async throws -> [Playlist] {
        var query = [
            URLQueryItem(name: "SortBy", value: sortOrder.rawValue),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
            URLQueryItem(name: "StartIndex", value: "0"),
            URLQueryItem(name: "IncludeItemTypes", value: "Playlist"),
            URLQueryItem(name: "IncludeMediaTypes", value: "Audio"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ParentId", value: "3996159c9706fc5500823e0316d260c1"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
        ]
        
        if limit > 0 {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if favorite {
            query.append(URLQueryItem(name: "Filters", value: "IsFavorite"))
        }
        
        let response = try await request(ClientRequest<PlaylistItemsResponse>(path: "Items", method: "GET", query: query, userPrefix: true))
        return response.Items.map(Playlist.convertFromJellyfin)
    }
    
    func getTracks(playlistId: String) async throws -> [Track] {
        let response = try await request(ClientRequest<TracksItemResponse>(path: "Playlists/\(playlistId)/Items", method: "GET", query: [
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ], userId: true))
        
        return response.Items.enumerated().map { Track.convertFromJellyfin($1, fallbackIndex: $0) }
    }
}
