//
//  File.swift
//
//
//  Created by Rasmus Krämer on 01.01.24.
//

import Foundation

public extension JellyfinClient {
    func create(playlistName: String, trackIds: [String]) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Playlists", method: "POST", body: [
            "Name": playlistName,
            "Ids": trackIds,
            "MediaType": "Audio",
        ], userId: true))
    }
    
    func getPlaylists(limit: Int, sortOrder: ItemSortOrder, ascending: Bool, favorite: Bool) async throws -> [Playlist] {
        var query = [
            URLQueryItem(name: "SortBy", value: sortOrder.rawValue),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
            URLQueryItem(name: "StartIndex", value: "0"),
            URLQueryItem(name: "IncludeItemTypes", value: "Playlist"),
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
        return response.Items.filter { $0.MediaType == "Audio" }.map(Playlist.convertFromJellyfin)
    }
    
    func getPlaylists(query: String) async throws -> [Playlist] {
        let response = try await request(ClientRequest<PlaylistItemsResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "searchTerm", value: query),
            URLQueryItem(name: "Limit", value: "20"),
            URLQueryItem(name: "IncludeItemTypes", value: "Playlist"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ParentId", value: "3996159c9706fc5500823e0316d260c1"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
        ], userPrefix: true))
        
        return response.Items.filter { $0.MediaType == "Audio" }.map(Playlist.convertFromJellyfin)
    }
    
    /// Get random albums
    func getPlaylists(limit: Int) async throws -> [Playlist] {
        let response = try await request(ClientRequest<PlaylistItemsResponse>(path: "Items", method: "GET", query: [
            URLQueryItem(name: "SortBy", value: "IsFavoriteOrLiked,Random"),
            URLQueryItem(name: "Limit", value: String(limit)),
            URLQueryItem(name: "IncludeItemTypes", value: "Playlist"),
            URLQueryItem(name: "Recursive", value: "true"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
        ], userPrefix: true))
        
        return response.Items.map(Playlist.convertFromJellyfin)
    }
    
    func add(trackIds: [String], playlistId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Playlists/\(playlistId)/Items", method: "POST", query: [
            URLQueryItem(name: "Ids", value: trackIds.joined(separator: ","))
        ], userId: true))
    }
    
    func remove(trackId: String, playlistId: String) async throws {
        let mappings = try await getTrackPlaylistIdsMapping(playlistId: playlistId)
        
        if let trackId = mappings.first(where: { $0.key == trackId })?.value {
            let _ = try await request(ClientRequest<EmptyResponse>(path: "Playlists/\(playlistId)/Items", method: "DELETE", query: [
                URLQueryItem(name: "EntryIds", value: trackId),
            ], userId: true))
        } else {
            throw JellyfinClientError.invalidHttpBody
        }
    }
    
    func move(trackId: String, index: Int, playlistId: String) async throws {
        let mappings = try await getTrackPlaylistIdsMapping(playlistId: playlistId)
        
        if let trackId = mappings.first(where: { $0.key == trackId })?.value {
            let _ = try await request(ClientRequest<EmptyResponse>(path: "Playlists/\(playlistId)/Items/\(trackId)/Move/\(index)", method: "POST", userId: true))
        } else {
            throw JellyfinClientError.invalidHttpBody
        }
    }
    
    func getTracks(playlistId: String) async throws -> [Track] {
        let response = try await request(ClientRequest<TracksItemResponse>(path: "Playlists/\(playlistId)/Items", method: "GET", query: [
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ], userId: true))
        
        return response.Items.enumerated().compactMap { try? Track.convertFromJellyfin($1, fallbackIndex: $0) }
    }
    
    func getTrackPlaylistIdsMapping(playlistId: String) async throws -> [String: String] {
        let response = try await request(ClientRequest<TracksItemResponse>(path: "Playlists/\(playlistId)/Items", method: "GET", query: [
            URLQueryItem(name: "IncludeItemTypes", value: "Audio"),
            URLQueryItem(name: "ImageTypeLimit", value: "1"),
            URLQueryItem(name: "EnableImageTypes", value: "Primary"),
            URLQueryItem(name: "Fields", value: "AudioInfo,ParentId"),
        ], userId: true))
        
        var mapping = [String: String]()
        response.Items.forEach {
            mapping[$0.Id] = $0.PlaylistItemId
        }
        
        return mapping
    }
}
