//
//  File.swift
//
//
//  Created by Rasmus Krämer on 01.01.24.
//

import Foundation
import AFFoundation

private let playlistQuery = [
    URLQueryItem(name: "IncludeItemTypes", value: "Playlist"),
    URLQueryItem(name: "Recursive", value: "true"),
    URLQueryItem(name: "ImageTypeLimit", value: "1"),
    URLQueryItem(name: "EnableImageTypes", value: "Primary"),
]

public extension JellyfinClient {
    func create(playlistName: String, trackIds: [String], IsPublic: Bool) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Playlists", method: "POST", body: [
            "Ids": trackIds,
            "Name": playlistName,
            "MediaType": "Audio",
            "IsPublic": IsPublic
        ], userId: true))
    }
    
    func playlists(limit: Int, sortOrder: ItemSortOrder, ascending: Bool, favoriteOnly: Bool = false, search: String? = nil) async throws -> [Playlist] {
        var query = [
            URLQueryItem(name: "StartIndex", value: "0"),
            URLQueryItem(name: "SortBy", value: sortOrder.value),
            URLQueryItem(name: "SortOrder", value: ascending ? "Ascending" : "Descending"),
        ]
        
        query += playlistQuery
        
        if limit > 0 {
            query.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if favoriteOnly {
            query.append(URLQueryItem(name: "Filters", value: "IsFavorite"))
        }
        
        if let search = search {
            query.append(URLQueryItem(name: "searchTerm", value: search))
        }
        
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Items", method: "GET", query: query, userPrefix: true))
        return response.Items.filter { $0.MediaType == "Audio" }.map(Playlist.init)
    }
    
    func playlist(identifier: String) async throws -> Playlist {
        guard let playlist = try? await request(ClientRequest<JellyfinItem>(path: "Items/\(identifier)", method: "GET", query: playlistQuery, userPrefix: true)) else {
            throw ClientError.invalidResponse
        }
        
        return .init(playlist)
    }
    
    func trackMappings(playlistId identifier: String) async throws -> [String: String] {
        let response = try await request(ClientRequest<JellyfinItemsResponse>(path: "Playlists/\(identifier)/Items", method: "GET", userId: true))
        
        var mappings = [String: String]()
        response.Items.forEach {
            mappings[$0.Id] = $0.PlaylistItemId
        }
        
        return mappings
    }
    
    func add(trackIds: [String], playlistId: String) async throws {
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Playlists/\(playlistId)/Items", method: "POST", query: [
            URLQueryItem(name: "Ids", value: trackIds.joined(separator: ","))
        ], userId: true))
    }
    
    func remove(trackId: String, playlistId: String) async throws {
        let mappings = try await trackMappings(playlistId: playlistId)
        
        guard let trackId = mappings.first(where: { $0.key == trackId })?.value else {
            throw ClientError.parseFailed
        }
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Playlists/\(playlistId)/Items", method: "DELETE", query: [
            URLQueryItem(name: "EntryIds", value: trackId),
        ], userId: true))
    }
    
    func move(trackId: String, index: Int, playlistId: String) async throws {
        let mappings = try await trackMappings(playlistId: playlistId)
        
        guard let trackId = mappings.first(where: { $0.key == trackId })?.value else {
            throw ClientError.invalidHttpBody
        }
        
        let _ = try await request(ClientRequest<EmptyResponse>(path: "Playlists/\(playlistId)/Items/\(trackId)/Move/\(index)", method: "POST", userId: true))
    }
}
